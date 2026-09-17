import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/document_compressor_providers.dart';
import '../../../../core/files/document_compressor.dart';
import '../../../../shared/constants/event_types.dart';
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
    this.errorMessage,
    this.fieldErrors = const {},
    this.saved = false,
    this.photoSlots = const [],
    this.uploadedPhotos = const [],
  });

  final HostEvent draft;
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

  /// Format options are the same shared `kEventTypeOptions` vocabulary
  /// H-07 uses for a venue's `allowedEventTypes` — not scoped to the
  /// selected venue's own subset, since `GET /api/v1/venues` (the list
  /// endpoint this screen's venue picker is populated from) never
  /// includes `allowedEventTypes` in the first place.
  List<String> get formatOptions => kEventTypeOptions;

  String get saveLabel => isEdit ? 'Save changes' : 'Submit';

  HostEventFormState copyWith({
    HostEvent? draft,
    bool? isEdit,
    bool? isLoadingEvent,
    String? loadError,
    List<HostVenue>? venues,
    bool? isLoadingVenues,
    String? venuesLoadError,
    bool? isSaving,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool? saved,
    List<AhPhotoSlotData>? photoSlots,
    List<HostEventPhoto?>? uploadedPhotos,
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
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      photoSlots: photoSlots ?? this.photoSlots,
      uploadedPhotos: uploadedPhotos ?? this.uploadedPhotos,
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
  /// immediately. Format isn't touched — it's the same shared
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
    }

    if (draft.doorsOpenAt == null) {
      errors['doorsOpenAt'] = 'Doors open time is required.';
    } else if (draft.startAt != null) {
      final doors = draft.doorsOpenAt!;
      final start = draft.startAt!;
      if (doors.isAfter(start)) {
        errors['doorsOpenAt'] = 'Doors must open before the start time.';
      } else if (doors.year != start.year ||
          doors.month != start.month ||
          doors.day != start.day) {
        errors['doorsOpenAt'] = 'Doors must open on the same day as start.';
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
      errors['cancellationTerms'] =
          'Cancellation terms must be 1000 characters or fewer.';
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
            'Refund cutoff would already have passed — pick a later start '
            'time or a shorter cutoff.';
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
}
