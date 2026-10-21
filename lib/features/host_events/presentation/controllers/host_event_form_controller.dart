import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/document_compressor_providers.dart';
import '../../../../core/files/document_compressor.dart';
import '../../../../core/time/server_clock.dart';
import '../../../../shared/constants/event_types.dart';
import '../../../../shared/utils/option_filter.dart';
import '../../../../shared/widgets/ah_photo_slots.dart';
import '../../../host_venues/domain/entities/host_venue.dart';
import '../../../host_venues/presentation/controllers/host_venues_api_providers.dart';
import '../../domain/entities/host_event.dart';
import '../../domain/entities/host_event_photo.dart';
import 'host_events_api_providers.dart';

part 'host_event_form_controller.g.dart';

/// Minimum number of successfully uploaded photos (cover + gallery
/// combined) required before an event can be submitted, per H-08's
/// "Minimum 3 photos" helper copy — the backend itself treats both as
/// optional.
const kMinEventPhotos = 3;

/// The first uploaded photo becomes [HostEvent.coverPhoto] and is also
/// included in [HostEvent.photos] (the backend expects the cover to be a
/// member of the gallery, not separate from it) — so this is the
/// gallery's own max of 5, not 5 plus a cover slot.
const kMaxEventPhotos = 5;

/// Capacity stepper bounds, per H-08's `StepperInput` — deliberately
/// different from a venue's own `maxCapacity` field (min 1, no fixed step).
const kEventCapacityMin = 10;
const kEventCapacityMax = 200;
const kEventCapacityStep = 2;

/// Doors may open no earlier than this far before the event's start time.
const kMaxDoorsOpenLeadTime = Duration(hours: 1, minutes: 30);

/// An event may run at most this long (API rejects `endsAt` beyond it).
const kMaxEventDuration = Duration(hours: 12);

/// Result of [HostEventFormController.saveAndSubmit].
enum HostEventSubmitOutcome {
  /// Saved and moved to `submitted`.
  submitted,

  /// Saved as a draft, but the `/submit` call itself failed — the draft
  /// isn't lost, and [HostEventFormState.errorMessage] says why.
  savedAsDraftOnly,

  /// Nothing was saved (validation or save error).
  failed,
}

class HostEventFormState {
  const HostEventFormState({
    required this.draft,
    required this.isEdit,
    this.isLoadingEvent = false,
    this.loadError,
    this.venues = const [],
    this.isLoadingVenues = false,
    this.venuesLoadError,
    this.isSaving = false,
    this.isCancelling = false,
    this.isDeleting = false,
    this.errorMessage,
    this.fieldErrors = const {},
    this.saved = false,
    this.photoSlots = const [],
    this.uploadedPhotos = const [],
    this.hasEnded = false,
  });

  final HostEvent draft;

  /// The loaded event is over (see [HostEvent.hasEndedAt]) — nothing can
  /// be done to it any more, including cancelling.
  final bool hasEnded;
  final bool isEdit;

  /// True while the full event is being fetched for edit mode.
  final bool isLoadingEvent;

  /// Set when fetching the event for edit mode fails; [retryLoadEvent]
  /// clears it.
  final String? loadError;

  /// The host's saved venues, for the Venue dropdown. Reuses
  /// `host_venues`'s existing `GetHostVenuesUseCase` rather than a
  /// separate fetch.
  final List<HostVenue> venues;
  final bool isLoadingVenues;
  final String? venuesLoadError;

  final bool isSaving;

  /// True while `POST /api/v1/host/events/{id}/cancel` is in flight.
  final bool isCancelling;

  /// True while `DELETE /api/v1/host/events/{id}` is in flight.
  final bool isDeleting;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final bool saved;

  /// Per-slot upload progress for cover photos — mirrors
  /// `HostVenueFormState.photoSlots`.
  final List<AhPhotoSlotData> photoSlots;

  /// The actual uploaded [HostEventPhoto] per slot index, parallel to
  /// [photoSlots] (null for a slot that isn't uploaded yet). Kept separate
  /// from [draft] until [save] splits index 0 into `coverPhoto` and the
  /// rest into the gallery `photos` list the backend expects.
  final List<HostEventPhoto?> uploadedPhotos;

  /// The currently selected venue, if any — drives the format options list
  /// and the read-only address box.
  HostVenue? get selectedVenue {
    if (draft.venueId.isEmpty) return null;
    for (final venue in venues) {
      if (venue.id == draft.venueId) return venue;
    }
    return null;
  }

  /// Every event format — not scoped to the selected venue, whose
  /// `allowedVenueTypes` describe the place, not the events it hosts.
  List<String> get formatOptions => kEventTypeOptions;

  /// Only drafts can be edited (`PATCH` is draft-only) and submitted —
  /// a new event is a draft-to-be.
  bool get isEditable =>
      !isEdit || draft.status == HostEventLifecycleStatus.draft;

  /// Submitted (awaiting review) and published events can be cancelled,
  /// until they've ended.
  bool get canCancel =>
      !hasEnded &&
      (draft.status == HostEventLifecycleStatus.submitted ||
          draft.status == HostEventLifecycleStatus.published);

  bool get isBusy => isSaving || isCancelling || isDeleting;

  /// Only a draft that already exists on the server can be deleted — a
  /// new, never-saved event has nothing to delete.
  bool get canDelete =>
      isEdit &&
      draft.id.isNotEmpty &&
      draft.status == HostEventLifecycleStatus.draft;

  HostEventFormState copyWith({
    HostEvent? draft,
    bool? isEdit,
    bool? isLoadingEvent,
    String? loadError,
    List<HostVenue>? venues,
    bool? isLoadingVenues,
    String? venuesLoadError,
    bool? isSaving,
    bool? isCancelling,
    bool? isDeleting,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool? saved,
    List<AhPhotoSlotData>? photoSlots,
    List<HostEventPhoto?>? uploadedPhotos,
    bool? hasEnded,
  }) {
    return HostEventFormState(
      draft: draft ?? this.draft,
      isEdit: isEdit ?? this.isEdit,
      isLoadingEvent: isLoadingEvent ?? this.isLoadingEvent,
      loadError: loadError,
      venues: venues ?? this.venues,
      isLoadingVenues: isLoadingVenues ?? this.isLoadingVenues,
      venuesLoadError: venuesLoadError,
      isSaving: isSaving ?? this.isSaving,
      isCancelling: isCancelling ?? this.isCancelling,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      photoSlots: photoSlots ?? this.photoSlots,
      uploadedPhotos: uploadedPhotos ?? this.uploadedPhotos,
      hasEnded: hasEnded ?? this.hasEnded,
    );
  }
}

/// H-08 · New event — also backs the H-E1 "edit event" mode when [eventId]
/// is non-null, mirroring `HostVenueFormController`. The full event
/// (including its cover/gallery photos) is fetched fresh on every open
/// rather than passed via navigation `extra`, since the H-05 Home list
/// response may not carry everything this form needs.
@riverpod
class HostEventFormController extends _$HostEventFormController {
  @override
  HostEventFormState build(String? eventId) {
    Future.microtask(_loadVenues);
    if (eventId == null) {
      return const HostEventFormState(draft: HostEvent.empty, isEdit: false);
    }
    Future.microtask(_loadEvent);
    return const HostEventFormState(
      draft: HostEvent.empty,
      isEdit: true,
      isLoadingEvent: true,
    );
  }

  Future<void> _loadEvent() async {
    final id = eventId;
    if (id == null) return;
    state = state.copyWith(isLoadingEvent: true, loadError: null);
    final useCase = ref.read(getHostEventByIdUseCaseProvider);
    final result = await useCase(id);
    state = result.when(
      ok: (event) => state.copyWith(
        draft: event,
        isLoadingEvent: false,
        hasEnded: event.hasEndedAt(ref.read(serverClockProvider).now()),
        photoSlots: _photoSlotsFor(event),
        uploadedPhotos: _uploadedPhotosFor(event),
      ),
      err: (failure) =>
          state.copyWith(isLoadingEvent: false, loadError: failure.message),
    );
    // The venue backing this event comes from the same list-sourced
    // dropdown data (maxCapacity always 0) until refreshed — same fix as
    // updateVenue's fresh-pick path.
    if (state.draft.venueId.isNotEmpty) {
      unawaited(_refreshVenueDetail(state.draft.venueId));
    }
  }

  /// Retries the initial fetch after [HostEventFormState.loadError] —
  /// surfaced so the screen never has to stay blank on a failed load.
  void retryLoadEvent() {
    Future.microtask(_loadEvent);
  }

  /// Seeds per-slot upload state from an existing event's cover + gallery
  /// photos — slot 0 is the cover (if any), the rest are the gallery,
  /// mirroring how [save] splits them back apart on write.
  List<AhPhotoSlotData> _photoSlotsFor(HostEvent event) {
    final photos = [
      if (event.coverPhoto != null) event.coverPhoto!,
      ...event.photos,
    ];
    return [
      for (final photo in photos)
        AhPhotoSlotData(
          status: AhPhotoSlotStatus.uploaded,
          networkUrl: photo.url,
        ),
    ];
  }

  List<HostEventPhoto?> _uploadedPhotosFor(HostEvent event) {
    return [if (event.coverPhoto != null) event.coverPhoto!, ...event.photos];
  }

  Future<void> _loadVenues() async {
    state = state.copyWith(isLoadingVenues: true, venuesLoadError: null);
    final useCase = ref.read(getHostVenuesUseCaseProvider);
    final result = await useCase();
    state = result.when(
      ok: (venues) => state.copyWith(venues: venues, isLoadingVenues: false),
      err: (failure) => state.copyWith(
        isLoadingVenues: false,
        venuesLoadError: failure.message,
      ),
    );
  }

  void retryLoadVenues() {
    Future.microtask(_loadVenues);
  }

  void updateTitle(String value) {
    state = state.copyWith(draft: state.draft.copyWith(title: value));
  }

  void updateDescription(String value) {
    state = state.copyWith(draft: state.draft.copyWith(description: value));
  }

  /// [HostEventFormState.formatOptions] filtered by [query], for the
  /// searchable Format field.
  List<String> searchFormats(String query) =>
      filterOptions(state.formatOptions, query);

  void updateFormat(String value) {
    state = state.copyWith(draft: state.draft.copyWith(format: value));
  }

  void updateStartAt(DateTime value) {
    state = state.copyWith(draft: state.draft.copyWith(startAt: value));
  }

  void updateEndAt(DateTime value) {
    state = state.copyWith(draft: state.draft.copyWith(endAt: value));
  }

  void updateDoorsOpenAt(DateTime value) {
    state = state.copyWith(draft: state.draft.copyWith(doorsOpenAt: value));
  }

  void updateRefundCutoffHours(int value) {
    state = state.copyWith(
      draft: state.draft.copyWith(refundCutoffHoursBeforeStart: value),
    );
  }

  /// Selecting a venue fills the read-only address/neighbourhood box
  /// immediately. Format isn't touched — it's the same
  /// `kEventTypeOptions` list regardless of venue (see [formatOptions]).
  ///
  /// Capacity is *not* clamped here: [venue] comes from `GET
  /// /api/v1/venues` (the list this screen's dropdown is populated from),
  /// which never includes `maxCapacity` — it's always 0 on a list-sourced
  /// venue. Clamping against that would incorrectly floor every event's
  /// capacity to [kEventCapacityMin] the instant a venue is picked. The
  /// real `maxCapacity` is fetched in the background by
  /// [_refreshVenueDetail] and only clamps capacity once it's known.
  void updateVenue(HostVenue venue) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        venueId: venue.id,
        venueAddress: venue.address,
        neighbourhood: venue.locality,
      ),
    );
    unawaited(_refreshVenueDetail(venue.id));
  }

  /// Fetches the full venue (with its real `maxCapacity`) and patches it
  /// into [HostEventFormState.venues] in place, so [selectedVenue] and
  /// every capacity calculation that reads it become accurate once this
  /// resolves. Best-effort: on failure the list-sourced venue (with
  /// `maxCapacity: 0`) is left as-is rather than blocking the form.
  Future<void> _refreshVenueDetail(String venueId) async {
    final useCase = ref.read(getHostVenueByIdUseCaseProvider);
    final result = await useCase(venueId);
    result.when(
      ok: (detailed) {
        // The host may have picked a different venue while this was in
        // flight — only apply the result if it's still the selected one.
        if (state.draft.venueId != venueId) return;
        final venues = [
          for (final v in state.venues) v.id == venueId ? detailed : v,
        ];
        final clampedCapacity = state.draft.capacity > detailed.maxCapacity
            ? _roundDownToStep(detailed.maxCapacity)
            : state.draft.capacity;
        state = state.copyWith(
          venues: venues,
          draft: state.draft.copyWith(capacity: clampedCapacity),
        );
      },
      err: (_) {},
    );
  }

  int _roundDownToStep(int value) {
    final steps = (value - kEventCapacityMin) ~/ kEventCapacityStep;
    final rounded = kEventCapacityMin + steps * kEventCapacityStep;
    return rounded.clamp(kEventCapacityMin, kEventCapacityMax);
  }

  void updateCapacity(int value) {
    final venue = state.selectedVenue;
    // The event capacity stepper (8-200 step 2) is deliberately separate
    // from a venue's own `maxCapacity` field, but it's an easy, obviously
    // correct constraint to also cap at the venue's own ceiling so a host
    // can't sell more seats than the room holds. The venue's maxCapacity
    // is clamped into the stepper's own [min, max] range first — a venue
    // can have maxCapacity below kEventCapacityMin (venues allow as low
    // as 1), and `int.clamp` throws if its own bounds are out of order.
    final effectiveMax = venue == null
        ? kEventCapacityMax
        : venue.maxCapacity.clamp(kEventCapacityMin, kEventCapacityMax);
    final capped = value.clamp(kEventCapacityMin, effectiveMax);
    state = state.copyWith(draft: state.draft.copyWith(capacity: capped));
  }

  void updateTicketPrice(int value) {
    state = state.copyWith(
      draft: state.draft.copyWith(ticketPriceRupees: value),
    );
  }

  void updateCancellationTerms(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(cancellationTerms: value),
    );
  }

  /// Clamped to [kRatioBandMinPoints]-[kRatioBandMaxPoints] — the band can
  /// only be narrowed, never widened past the platform default.
  void updateToleranceBandPoints(int value) {
    final clamped = value.clamp(kRatioBandMinPoints, kRatioBandMaxPoints);
    state = state.copyWith(
      draft: state.draft.copyWith(toleranceBandPoints: clamped),
    );
  }

  void toggleHoldback(bool value) {
    state = state.copyWith(draft: state.draft.copyWith(holdbackEnabled: value));
  }

  void pickPhotoAt(int index, String filePath, String fileName) {
    final slots = [...state.photoSlots];
    while (slots.length <= index) {
      slots.add(const AhPhotoSlotData());
    }
    slots[index] = AhPhotoSlotData(
      status: AhPhotoSlotStatus.uploading,
      localPath: filePath,
    );
    state = state.copyWith(photoSlots: slots);
    unawaited(_uploadInBackground(index, filePath, fileName));
  }

  Future<void> _uploadInBackground(
    int index,
    String filePath,
    String fileName,
  ) async {
    try {
      final compressor = ref.read(documentCompressorProvider);
      final uploadPath = await compressor.compress(filePath, fileName);
      final useCase = ref.read(uploadEventPhotoUseCaseProvider);
      final result = await useCase(filePath: uploadPath, fileName: fileName);
      if (index >= state.photoSlots.length ||
          state.photoSlots[index].localPath != filePath) {
        return;
      }
      result.when(
        ok: (photo) => _setSlot(
          index,
          AhPhotoSlotData(
            status: AhPhotoSlotStatus.uploaded,
            localPath: filePath,
            networkUrl: photo.url,
          ),
          photo: photo,
        ),
        err: (failure) => _setSlot(
          index,
          AhPhotoSlotData(
            status: AhPhotoSlotStatus.error,
            localPath: filePath,
            errorMessage: failure.message,
          ),
        ),
      );
    } on DocumentTooLargeException catch (e) {
      if (index >= state.photoSlots.length ||
          state.photoSlots[index].localPath != filePath) {
        return;
      }
      _setSlot(
        index,
        AhPhotoSlotData(
          status: AhPhotoSlotStatus.error,
          localPath: filePath,
          errorMessage: e.toString(),
        ),
      );
    } catch (_) {
      if (index >= state.photoSlots.length ||
          state.photoSlots[index].localPath != filePath) {
        return;
      }
      _setSlot(
        index,
        AhPhotoSlotData(
          status: AhPhotoSlotStatus.error,
          localPath: filePath,
          errorMessage: "Couldn't be uploaded",
        ),
      );
    }
  }

  void _setSlot(int index, AhPhotoSlotData value, {HostEventPhoto? photo}) {
    final slots = [...state.photoSlots];
    while (slots.length <= index) {
      slots.add(const AhPhotoSlotData());
    }
    slots[index] = value;

    final uploaded = [...state.uploadedPhotos];
    if (photo != null) {
      while (uploaded.length <= index) {
        uploaded.add(null);
      }
      uploaded[index] = photo;
    }
    state = state.copyWith(photoSlots: slots, uploadedPhotos: uploaded);
  }

  int _successfulPhotoUploadCount() {
    return state.photoSlots
        .where((slot) => slot.status == AhPhotoSlotStatus.uploaded)
        .length;
  }

  Map<String, String> _validate() {
    final draft = state.draft;
    final errors = <String, String>{};

    if (_successfulPhotoUploadCount() < kMinEventPhotos) {
      errors['photos'] = 'Add at least $kMinEventPhotos photos.';
    }

    final title = draft.title.trim();
    if (title.isEmpty) {
      errors['title'] = 'Title is required.';
    } else if (title.length > 200) {
      errors['title'] = 'Title must be 200 characters or fewer.';
    }

    final description = draft.description.trim();
    if (description.isEmpty) {
      errors['description'] = 'Description is required.';
    } else if (description.length > 2000) {
      errors['description'] = 'Description must be 2000 characters or fewer.';
    }

    if (draft.format.trim().isEmpty) {
      errors['format'] = 'Format is required.';
    }

    if (draft.startAt == null) {
      errors['startAt'] = 'Start date & time is required.';
    }
    if (draft.endAt == null) {
      errors['endAt'] = 'End date & time is required.';
    }
    if (draft.startAt != null &&
        draft.endAt != null &&
        !draft.endAt!.isAfter(draft.startAt!)) {
      errors['endAt'] = 'End must be after the start time.';
    } else if (draft.startAt != null &&
        draft.endAt != null &&
        draft.endAt!.difference(draft.startAt!) > kMaxEventDuration) {
      errors['endAt'] =
          'Event can run at most ${kMaxEventDuration.inHours} hours.';
    }

    if (draft.doorsOpenAt == null) {
      errors['doorsOpenAt'] = 'Doors open time is required.';
    } else if (draft.startAt != null) {
      final doors = draft.doorsOpenAt!;
      final start = draft.startAt!;
      if (doors.isAfter(start)) {
        errors['doorsOpenAt'] = 'Doors must open before the start time.';
      } else if (start.difference(doors) > kMaxDoorsOpenLeadTime) {
        errors['doorsOpenAt'] =
            'Doors can open at most ${kMaxDoorsOpenLeadTime.inMinutes / 60} '
            'hours before the start time.';
      }
    }

    if (draft.venueId.trim().isEmpty) {
      errors['venue'] = 'Venue is required.';
    }

    if (draft.capacity < kEventCapacityMin) {
      errors['capacity'] = 'Capacity must be at least $kEventCapacityMin.';
    }

    if (draft.ticketPriceRupees <= 0) {
      errors['ticketPrice'] = 'Ticket price is required.';
    }

    final cancellationTerms = draft.cancellationTerms.trim();
    if (cancellationTerms.isEmpty) {
      errors['cancellationTerms'] = 'Cancellation terms are required.';
    } else if (cancellationTerms.length > 1000) {
      errors['cancellationTerms'] = 'Max 1000 characters.';
    }

    // The computed refund cutoff (start minus this many hours) can't
    // already be in the past — an event starting soon with a long cutoff
    // would mean refunds were never actually possible. Confirmed against
    // the real API: every request with a near-term start and a cutoff
    // longer than the lead time to that start was rejected.
    if (draft.startAt != null) {
      final cutoff = draft.startAt!.subtract(
        Duration(hours: draft.refundCutoffHoursBeforeStart),
      );
      if (cutoff.isBefore(DateTime.now())) {
        errors['refundCutoffHoursBeforeStart'] =
            'Cutoff has already passed — shorten it.';
      }
    }

    return errors;
  }

  Future<bool> save() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    // Slot 0 becomes the single coverPhotoId. Every successfully uploaded
    // slot — including slot 0 — also goes into the gallery `photos` array:
    // the backend expects the cover photo to be a member of the gallery,
    // not a wholly separate image (confirmed against a real working
    // request, where coverPhotoId and photos[0] were the same id).
    HostEventPhoto? coverPhoto;
    final allPhotos = <HostEventPhoto>[];
    for (var i = 0; i < state.photoSlots.length; i++) {
      if (state.photoSlots[i].status != AhPhotoSlotStatus.uploaded ||
          i >= state.uploadedPhotos.length) {
        continue;
      }
      final photo = state.uploadedPhotos[i];
      if (photo == null) continue;
      if (i == 0) coverPhoto = photo;
      allPhotos.add(photo);
    }

    state = state.copyWith(
      isSaving: true,
      fieldErrors: const {},
      errorMessage: null,
      draft: state.draft.copyWith(
        coverPhoto: coverPhoto,
        photos: allPhotos.take(5).toList(),
      ),
    );
    final useCase = ref.read(saveHostEventUseCaseProvider);
    final result = await useCase(state.draft);
    state = result.when(
      ok: (event) => state.copyWith(draft: event, isSaving: false, saved: true),
      err: (failure) =>
          state.copyWith(isSaving: false, errorMessage: failure.message),
    );
    return state.saved;
  }

  /// Saves the draft (create or `PATCH`), then submits it for review via
  /// `POST /api/v1/host/events/{id}/submit`.
  Future<HostEventSubmitOutcome> saveAndSubmit() async {
    if (!await save()) return HostEventSubmitOutcome.failed;

    state = state.copyWith(isSaving: true, errorMessage: null);
    final useCase = ref.read(submitHostEventUseCaseProvider);
    final result = await useCase(state.draft.id);
    return result.when(
      ok: (event) {
        state = state.copyWith(draft: event, isSaving: false);
        return HostEventSubmitOutcome.submitted;
      },
      err: (failure) {
        state = state.copyWith(
          isSaving: false,
          errorMessage:
              "Saved as a draft, but couldn't submit it: ${failure.message}",
        );
        return HostEventSubmitOutcome.savedAsDraftOnly;
      },
    );
  }

  /// Cancels a submitted/published event via
  /// `POST /api/v1/host/events/{id}/cancel`, which also initiates
  /// attendee refunds on the backend.
  /// `DELETE /api/v1/host/events/{id}` for a draft. Returns true once
  /// deleted; on failure [HostEventFormState.errorMessage] is set.
  Future<bool> deleteEvent() async {
    if (!state.canDelete || state.isBusy) return false;
    state = state.copyWith(isDeleting: true, errorMessage: null);
    final result = await ref.read(deleteHostEventUseCaseProvider)(
      state.draft.id,
    );
    if (!ref.mounted) return false;
    return result.when(
      ok: (_) {
        state = state.copyWith(isDeleting: false);
        return true;
      },
      err: (failure) {
        state = state.copyWith(
          isDeleting: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> cancelEvent(String reason) async {
    if (!state.canCancel || state.isBusy) return false;
    state = state.copyWith(isCancelling: true, errorMessage: null);
    final useCase = ref.read(cancelHostEventUseCaseProvider);
    final result = await useCase(state.draft.id, reason: reason);
    return result.when(
      ok: (event) {
        state = state.copyWith(draft: event, isCancelling: false);
        return true;
      },
      err: (failure) {
        state = state.copyWith(
          isCancelling: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }
}
