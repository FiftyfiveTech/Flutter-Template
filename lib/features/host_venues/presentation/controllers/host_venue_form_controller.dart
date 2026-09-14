import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/host_venue.dart';
import 'host_venues_api_providers.dart';

part 'host_venue_form_controller.g.dart';

/// Minimum number of photos required before a venue can be saved, per
/// H-07's "Minimum 3" helper copy.
const kMinVenuePhotos = 3;

class HostVenueFormState {
  const HostVenueFormState({
    required this.draft,
    required this.isEdit,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
    this.fieldErrors = const {},
    this.saved = false,
    this.deleted = false,
  });

  final HostVenue draft;
  final bool isEdit;
  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final bool saved;
  final bool deleted;

  String get saveLabel => isEdit ? 'Save changes' : 'Save venue';

  HostVenueFormState copyWith({
    HostVenue? draft,
    bool? isEdit,
    bool? isSaving,
    bool? isDeleting,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool? saved,
    bool? deleted,
  }) {
    return HostVenueFormState(
      draft: draft ?? this.draft,
      isEdit: isEdit ?? this.isEdit,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      deleted: deleted ?? this.deleted,
    );
  }
}

/// H-07 · Venue details — also backs the H-E0 "add a venue" mode when
/// [initialVenue] is null. Controllers depend only on use cases.
@riverpod
class HostVenueFormController extends _$HostVenueFormController {
  @override
  HostVenueFormState build(HostVenue? initialVenue) {
    return HostVenueFormState(
      draft: initialVenue ?? HostVenue.empty,
      isEdit: initialVenue != null,
    );
  }

  void updateName(String value) {
    state = state.copyWith(draft: state.draft.copyWith(name: value));
  }

  void updateAddressLine1(String value) {
    state = state.copyWith(draft: state.draft.copyWith(addressLine1: value));
  }

  void updateAddressLine2(String value) {
    state = state.copyWith(draft: state.draft.copyWith(addressLine2: value));
  }

  void updateCity(String value) {
    state = state.copyWith(draft: state.draft.copyWith(city: value));
  }

  void updatePincode(String value) {
    state = state.copyWith(draft: state.draft.copyWith(pincode: value));
  }

  void updateMaxCapacity(int value) {
    state = state.copyWith(draft: state.draft.copyWith(maxCapacity: value));
  }

  void toggleEventType(String type) {
    final current = state.draft.eventTypes;
    final updated = current.contains(type)
        ? current.where((t) => t != type).toList()
        : [...current, type];
    state = state.copyWith(draft: state.draft.copyWith(eventTypes: updated));
  }

  void setPhotoAt(int index, String path) {
    final photos = [...state.draft.photoPaths];
    while (photos.length <= index) {
      photos.add('');
    }
    photos[index] = path;
    state = state.copyWith(
      draft: state.draft.copyWith(
        photoPaths: photos.where((p) => p.isNotEmpty).toList(),
      ),
    );
  }

  Map<String, String> _validate() {
    final draft = state.draft;
    final errors = <String, String>{};
    if (draft.name.trim().isEmpty) {
      errors['name'] = 'Venue name is required.';
    }
    if (draft.addressLine1.trim().isEmpty) {
      errors['addressLine1'] = 'Address line 1 is required.';
    }
    if (draft.city.trim().isEmpty) {
      errors['city'] = 'City is required.';
    }
    if (draft.pincode.trim().isEmpty) {
      errors['pincode'] = 'Pincode is required.';
    }
    if (draft.eventTypes.isEmpty) {
      errors['eventTypes'] = 'Select at least one event type.';
    }
    if (draft.photoPaths.length < kMinVenuePhotos) {
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

    state = state.copyWith(
      isSaving: true,
      fieldErrors: const {},
      errorMessage: null,
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
