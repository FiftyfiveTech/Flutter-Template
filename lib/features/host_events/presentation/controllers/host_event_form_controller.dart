import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/document_compressor_providers.dart';
import '../../../../core/files/document_compressor.dart';
import '../../../../shared/widgets/ah_photo_slots.dart';
import '../../../host_venues/domain/entities/host_venue.dart';
import '../../../host_venues/presentation/controllers/host_venues_api_providers.dart';
import '../../domain/entities/host_event.dart';
import '../../domain/entities/host_event_photo.dart';
import 'host_events_api_providers.dart';

part 'host_event_form_controller.g.dart';

/// Minimum number of successfully uploaded cover photos required before an
/// event can be submitted, per H-08's "Minimum 3 photos" helper copy.
const kMinEventPhotos = 3;

/// No explicit maximum is shown in the design (only "Minimum 3 photos") —
/// capped at the same 3 slots the design mocks up, since there's no
/// affordance in the markup to add a 4th. Revisit if a real backend
/// contract specifies otherwise.
const kMaxEventPhotos = 3;

/// Capacity stepper bounds, per H-08's `StepperInput` — deliberately
/// different from a venue's own `maxCapacity` field (min 1, no fixed step).
const kEventCapacityMin = 8;
const kEventCapacityMax = 200;
const kEventCapacityStep = 2;

class HostEventFormState {
  const HostEventFormState({
    required this.draft,
    this.venues = const [],
    this.isLoadingVenues = false,
    this.venuesLoadError,
    this.isSaving = false,
    this.errorMessage,
    this.fieldErrors = const {},
    this.saved = false,
    this.photoSlots = const [],
  });

  final HostEvent draft;

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

  /// The currently selected venue, if any — drives the format options list
  /// and the read-only address box.
  HostVenue? get selectedVenue {
    if (draft.venueId.isEmpty) return null;
    for (final venue in venues) {
      if (venue.id == draft.venueId) return venue;
    }
    return null;
  }

  /// Format options come from the selected venue's `allowedEventTypes` —
  /// a venue only ever hosts the event types it was configured for in
  /// H-07. Empty (no options, dropdown disabled) until a venue is chosen.
  List<String> get formatOptions =>
      selectedVenue?.allowedEventTypes ?? const [];

  HostEventFormState copyWith({
    HostEvent? draft,
    List<HostVenue>? venues,
    bool? isLoadingVenues,
    String? venuesLoadError,
    bool? isSaving,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool? saved,
    List<AhPhotoSlotData>? photoSlots,
  }) {
    return HostEventFormState(
      draft: draft ?? this.draft,
      venues: venues ?? this.venues,
      isLoadingVenues: isLoadingVenues ?? this.isLoadingVenues,
      venuesLoadError: venuesLoadError,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      photoSlots: photoSlots ?? this.photoSlots,
    );
  }
}

/// H-08 · New event — create-only. There is no existing event to lock
/// price/date/capacity against yet (that's H-E1, editing an existing,
/// already-selling event — out of scope here).
@riverpod
class HostEventFormController extends _$HostEventFormController {
  @override
  HostEventFormState build() {
    Future.microtask(_loadVenues);
    return const HostEventFormState(
      draft: HostEvent.empty,
      isLoadingVenues: true,
    );
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

  /// Selecting a venue also fills the read-only address box and clears a
  /// format choice that no longer belongs to the newly-selected venue's
  /// `allowedEventTypes`, and clamps capacity to the new venue's
  /// `maxCapacity` if it's currently above it.
  void updateVenue(HostVenue venue) {
    final formatStillValid = venue.allowedEventTypes.contains(
      state.draft.format,
    );
    final clampedCapacity = state.draft.capacity > venue.maxCapacity
        ? _roundDownToStep(venue.maxCapacity)
        : state.draft.capacity;
    state = state.copyWith(
      draft: state.draft.copyWith(
        venueId: venue.id,
        venueAddress: venue.address,
        format: formatStillValid ? state.draft.format : '',
        capacity: clampedCapacity,
      ),
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
    // can't sell more seats than the room holds.
    final capped = venue == null
        ? value
        : value.clamp(kEventCapacityMin, venue.maxCapacity);
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

  void toggleTightenRatio(bool value) {
    state = state.copyWith(draft: state.draft.copyWith(ratioTightened: value));
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

    var photos = [...state.draft.photos];
    if (photo != null) {
      while (photos.length <= index) {
        photos.add(photo);
      }
      photos[index] = photo;
    }
    state = state.copyWith(
      photoSlots: slots,
      draft: state.draft.copyWith(photos: photos),
    );
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

    return errors;
  }

  Future<bool> save() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    final successfulPhotos = <HostEventPhoto>[
      for (var i = 0; i < state.photoSlots.length; i++)
        if (state.photoSlots[i].status == AhPhotoSlotStatus.uploaded &&
            i < state.draft.photos.length)
          state.draft.photos[i],
    ].take(kMaxEventPhotos).toList();

    state = state.copyWith(
      isSaving: true,
      fieldErrors: const {},
      errorMessage: null,
      draft: state.draft.copyWith(photos: successfulPhotos),
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
