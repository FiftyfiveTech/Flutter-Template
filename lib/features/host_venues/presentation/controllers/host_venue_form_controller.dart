import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/document_compressor_providers.dart';
import '../../../../core/files/document_compressor.dart';
import '../../../../shared/widgets/ah_photo_slots.dart';
import '../../../host_onboarding/domain/entities/city.dart';
import '../../../../shared/constants/venue_types.dart';
import '../../../../shared/utils/option_filter.dart';
import '../../domain/entities/host_venue.dart';
import '../../domain/entities/host_venue_photo.dart';
import 'host_venues_api_providers.dart';

part 'host_venue_form_controller.g.dart';

/// Minimum number of successfully uploaded photos required before a venue
/// can be saved, per H-07's "Minimum 3" helper copy.
const kMinVenuePhotos = 3;

/// Maximum number of photos a venue can carry — matches the backend's
/// "PATCH replaces the whole array, max 5 ids" contract.
const kMaxVenuePhotos = 5;

class HostVenueFormState {
  const HostVenueFormState({
    required this.draft,
    required this.isEdit,
    this.isLoadingVenue = false,
    this.loadError,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
    this.fieldErrors = const {},
    this.saved = false,
    this.deleted = false,
    this.photoSlots = const [],
  });

  final HostVenue draft;
  final bool isEdit;

  /// True while the full venue is being fetched for edit mode.
  final bool isLoadingVenue;

  /// Set when fetching the venue for edit mode fails; [retryLoad] clears it.
  final String? loadError;

  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final bool saved;
  final bool deleted;

  /// Per-slot upload progress for every photo picked/uploaded/saved so far
  /// — length grows as photos are added (up to [kMaxVenuePhotos]). The
  /// screen displays one extra empty "add" slot on top of this, down to
  /// [kMinVenuePhotos] shown at minimum.
  final List<AhPhotoSlotData> photoSlots;

  String get saveLabel => isEdit ? 'Save changes' : 'Save venue';

  HostVenueFormState copyWith({
    HostVenue? draft,
    bool? isEdit,
    bool? isLoadingVenue,
    String? loadError,
    bool? isSaving,
    bool? isDeleting,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool? saved,
    bool? deleted,
    List<AhPhotoSlotData>? photoSlots,
  }) {
    return HostVenueFormState(
      draft: draft ?? this.draft,
      isEdit: isEdit ?? this.isEdit,
      isLoadingVenue: isLoadingVenue ?? this.isLoadingVenue,
      loadError: loadError,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      deleted: deleted ?? this.deleted,
      photoSlots: photoSlots ?? this.photoSlots,
    );
  }
}

/// H-07 · Venue details — also backs the H-E0 "add a venue" mode when
/// [venueId] is null. Controllers depend only on use cases. In edit mode,
/// the full venue (including its short-lived photo urls) is fetched fresh
/// on every open rather than passed via navigation `extra`, since the
/// H-06 list response never includes photos.
@riverpod
class HostVenueFormController extends _$HostVenueFormController {
  @override
  HostVenueFormState build(String? venueId) {
    if (venueId == null) {
      return const HostVenueFormState(draft: HostVenue.empty, isEdit: false);
    }
    Future.microtask(_loadVenue);
    return const HostVenueFormState(
      draft: HostVenue.empty,
      isEdit: true,
      isLoadingVenue: true,
    );
  }

  Future<void> _loadVenue() async {
    final id = venueId;
    if (id == null) return;
    state = state.copyWith(isLoadingVenue: true, loadError: null);
    final useCase = ref.read(getHostVenueByIdUseCaseProvider);
    final result = await useCase(id);
    state = result.when(
      ok: (venue) => state.copyWith(
        draft: venue,
        isLoadingVenue: false,
        photoSlots: [
          for (final photo in venue.photos)
            AhPhotoSlotData(
              status: AhPhotoSlotStatus.uploaded,
              networkUrl: photo.url,
            ),
        ],
      ),
      err: (failure) =>
          state.copyWith(isLoadingVenue: false, loadError: failure.message),
    );
  }

  /// Retries the initial fetch after [loadError] — surfaced so the screen
  /// never has to stay blank on a failed load.
  void retryLoad() {
    Future.microtask(_loadVenue);
  }

  void updateName(String value) {
    state = state.copyWith(draft: state.draft.copyWith(name: value));
  }

  void updateAddLine1(String value) {
    state = state.copyWith(draft: state.draft.copyWith(addLine1: value));
  }

  void updateAddLine2(String value) {
    state = state.copyWith(draft: state.draft.copyWith(addLine2: value));
  }

  void updateLocality(String value) {
    state = state.copyWith(draft: state.draft.copyWith(locality: value));
  }

  void updateCity(City city) {
    state = state.copyWith(
      draft: state.draft.copyWith(cityId: city.id, cityName: city.name),
    );
  }

  void updatePincode(String value) {
    state = state.copyWith(draft: state.draft.copyWith(pincode: value));
  }

  void updateMaxCapacity(int value) {
    state = state.copyWith(draft: state.draft.copyWith(maxCapacity: value));
  }

  /// Venue types still available to add, filtered by [query] — feeds the
  /// searchable picker, so already-picked types aren't offered twice.
  List<String> searchVenueTypes(String query) => filterOptions(
    kVenueTypeOptions,
    query,
    exclude: state.draft.allowedVenueTypes,
  );

  void addVenueType(String type) {
    final current = state.draft.allowedVenueTypes;
    if (current.contains(type)) return;
    state = state.copyWith(
      draft: state.draft.copyWith(allowedVenueTypes: [...current, type]),
    );
  }

  void toggleVenueType(String type) {
    final current = state.draft.allowedVenueTypes;
    final updated = current.contains(type)
        ? current.where((t) => t != type).toList()
        : [...current, type];
    state = state.copyWith(
      draft: state.draft.copyWith(allowedVenueTypes: updated),
    );
  }

  /// Records the pick immediately (so the slot shows the local file) and
  /// kicks off compression + upload in the background — mirrors
  /// `HostDocumentsController.selectDocument`. Errors surface later via
  /// [HostVenueFormState.photoSlots] instead of a thrown exception.
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
      final useCase = ref.read(uploadVenuePhotoUseCaseProvider);
      final result = await useCase(filePath: uploadPath, fileName: fileName);
      // A newer pick for this slot may have started (and overwritten this
      // entry) while the upload was in flight — don't clobber it with a
      // stale result.
      if (index >= state.photoSlots.length ||
          state.photoSlots[index].localPath != filePath) {
        return;
      }
      result.when(
        ok: (photo) => _setSlot(
          index,
          AhPhotoSlotData(
            status: AhPhotoSlotStatus.uploaded,
            // Keep showing the local file rather than the presigned
            // networkUrl: it's guaranteed reachable, whereas the backend's
            // presigned url can point at a host the running app can't
            // reach (e.g. its own localhost). networkUrl is only relied
            // on for photos with no local file at all (loaded from an
            // existing venue in edit mode).
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

  void _setSlot(int index, AhPhotoSlotData value, {HostVenuePhoto? photo}) {
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

    final name = draft.name.trim();
    if (name.isEmpty) {
      errors['name'] = 'Venue name is required.';
    } else if (name.length > 200) {
      errors['name'] = 'Venue name must be 200 characters or fewer.';
    }

    final addLine1 = draft.addLine1.trim();
    if (addLine1.isEmpty) {
      errors['addLine1'] = 'Address line 1 is required.';
    } else if (addLine1.length > 200) {
      errors['addLine1'] = 'Max 200 characters.';
    }

    if (draft.addLine2.trim().length > 200) {
      errors['addLine2'] = 'Max 200 characters.';
    }

    final locality = draft.locality.trim();
    if (locality.isEmpty) {
      errors['locality'] = 'Locality is required.';
    } else if (locality.length > 100) {
      errors['locality'] = 'Locality must be 100 characters or fewer.';
    }

    if (draft.cityId.trim().isEmpty) {
      errors['city'] = 'City is required.';
    }

    final pincode = draft.pincode.trim();
    if (pincode.isEmpty) {
      errors['pincode'] = 'Pincode is required.';
    } else if (pincode.length > 12) {
      errors['pincode'] = 'Pincode must be 12 characters or fewer.';
    }

    if (draft.maxCapacity < 1) {
      errors['maxCapacity'] = 'Capacity must be at least 1.';
    }

    if (draft.allowedVenueTypes.isEmpty) {
      errors['venueTypes'] = 'Select at least one venue type.';
    }
    if (_successfulPhotoUploadCount() < kMinVenuePhotos) {
      errors['photos'] = 'Add at least $kMinVenuePhotos photos.';
    }
    return errors;
  }

  Future<bool> save() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    // Only currently-successful uploads are sent — uploading/failed slots
    // are skipped rather than blocking the rest of the form.
    final successfulPhotos = <HostVenuePhoto>[
      for (var i = 0; i < state.photoSlots.length; i++)
        if (state.photoSlots[i].status == AhPhotoSlotStatus.uploaded &&
            i < state.draft.photos.length)
          state.draft.photos[i],
    ].take(kMaxVenuePhotos).toList();

    state = state.copyWith(
      isSaving: true,
      fieldErrors: const {},
      errorMessage: null,
      draft: state.draft.copyWith(photos: successfulPhotos),
    );
    final useCase = ref.read(saveHostVenueUseCaseProvider);
    final result = await useCase(state.draft);
    state = result.when(
      ok: (venue) => state.copyWith(draft: venue, isSaving: false, saved: true),
      err: (failure) =>
          state.copyWith(isSaving: false, errorMessage: failure.message),
    );
    return state.saved;
  }

  Future<bool> delete() async {
    if (!state.isEdit) return false;
    state = state.copyWith(isDeleting: true, errorMessage: null);
    final useCase = ref.read(deleteHostVenueUseCaseProvider);
    final result = await useCase(state.draft.id);
    state = result.when(
      ok: (_) => state.copyWith(isDeleting: false, deleted: true),
      err: (failure) =>
          state.copyWith(isDeleting: false, errorMessage: failure.message),
    );
    return state.deleted;
  }
}
