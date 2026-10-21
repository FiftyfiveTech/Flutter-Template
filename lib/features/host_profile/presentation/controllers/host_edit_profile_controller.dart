import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/session/host_session.dart';
import '../../domain/entities/host_profile_edit.dart';
import '../../domain/usecases/update_host_profile.dart';
import 'host_profile_providers.dart';

part 'host_edit_profile_controller.g.dart';

class HostEditProfileState {
  const HostEditProfileState({
    this.isLoading = false,
    this.firstName = '',
    this.lastName = '',
    this.businessName = '',
    this.photoPath,
    this.pickedPhotoPath,
    this.fieldErrors = const {},
    this.isSaving = false,
    this.submitError,
  });

  final bool isLoading;

  /// Values the form was opened with — the save only sends fields that
  /// differ from these.
  final String firstName;
  final String lastName;
  final String businessName;

  /// The currently saved avatar (private local copy), if any.
  final String? photoPath;

  /// A newly picked image not yet saved — previewed in place of
  /// [photoPath] until Save uploads it.
  final String? pickedPhotoPath;

  final Map<String, String> fieldErrors;
  final bool isSaving;

  /// Set when the save fails for a reason not tied to a visible field.
  final String? submitError;

  HostEditProfileState copyWith({
    bool? isLoading,
    String? firstName,
    String? lastName,
    String? businessName,
    String? photoPath,
    String? pickedPhotoPath,
    Map<String, String>? fieldErrors,
    bool? isSaving,
    String? submitError,
  }) {
    return HostEditProfileState(
      isLoading: isLoading ?? this.isLoading,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      businessName: businessName ?? this.businessName,
      photoPath: photoPath ?? this.photoPath,
      pickedPhotoPath: pickedPhotoPath ?? this.pickedPhotoPath,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSaving: isSaving ?? this.isSaving,
      submitError: submitError,
    );
  }
}

/// Fields shown on Edit profile — server field errors for anything else
/// (e.g. `photoUploadId`) are surfaced as [HostEditProfileState.submitError].
const _formFields = {'firstName', 'lastName', 'businessName'};

/// Edit profile — prefilled from the cached profile (there's no profile
/// GET endpoint), saved via `PATCH /api/v1/host/profile`.
@riverpod
class HostEditProfileController extends _$HostEditProfileController {
  @override
  HostEditProfileState build() {
    Future.microtask(_load);
    return const HostEditProfileState(isLoading: true);
  }

  HostSession? get _session => ref.read(hostSessionControllerProvider);

  Future<void> _load() async {
    final result = await ref.read(getCachedHostProfileUseCaseProvider)(
      _session?.userId ?? '',
    );
    if (!ref.mounted) return;
    final cached = result.when(ok: (p) => p, err: (_) => null);
    final cachedName = cached?.hostName ?? '';
    state = state.copyWith(
      isLoading: false,
      firstName: cached?.firstName ?? '',
      lastName: cached?.lastName ?? '',
      businessName: cachedName.isEmpty
          ? (_session?.businessName ?? '')
          : cachedName,
      photoPath: cached?.photoPath,
    );
  }

  void pickPhoto(String sourcePath) {
    state = state.copyWith(pickedPhotoPath: sourcePath);
  }

  /// Saves the changed fields. Returns true once saved (or when nothing
  /// changed); on failure, [HostEditProfileState.fieldErrors] or
  /// [HostEditProfileState.submitError] is populated.
  Future<bool> save({
    required String firstName,
    required String lastName,
    required String businessName,
  }) async {
    String? changed(String value, String initial) {
      final trimmed = value.trim();
      return trimmed == initial ? null : trimmed;
    }

    final edit = HostProfileEdit(
      firstName: changed(firstName, state.firstName),
      lastName: changed(lastName, state.lastName),
      businessName: changed(businessName, state.businessName),
      photoSourcePath: state.pickedPhotoPath,
    );
    if (edit.isEmpty) return true;

    state = state.copyWith(isSaving: true, fieldErrors: const {});
    final session = _session;
    final result = await ref.read(updateHostProfileUseCaseProvider)(
      session?.userId ?? '',
      edit,
    );
    if (!ref.mounted) return false;

    return result.when(
      ok: (profile) {
        // The session's business name backs the You tab's name fallback.
        if (session != null && profile.hostName.isNotEmpty) {
          ref
              .read(hostSessionControllerProvider.notifier)
              .setSession(
                HostSession(
                  accessToken: session.accessToken,
                  userId: session.userId,
                  accountStatus: session.accountStatus,
                  businessName: profile.hostName,
                ),
              );
        }
        state = state.copyWith(isSaving: false);
        return true;
      },
      err: (failure) {
        final fieldErrors = failure is HostProfileValidationFailure
            ? failure.fieldErrors
            : const <String, String>{};
        final hasHiddenError = fieldErrors.keys.any(
          (field) => !_formFields.contains(field),
        );
        state = state.copyWith(
          isSaving: false,
          fieldErrors: fieldErrors,
          submitError: fieldErrors.isEmpty || hasHiddenError
              ? failure.message
              : null,
        );
        return false;
      },
    );
  }
}
