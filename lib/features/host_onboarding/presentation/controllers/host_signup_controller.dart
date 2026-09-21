import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/session/host_session.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/host_onboarding_step.dart';
import '../../domain/entities/host_signup_draft.dart';
import '../../domain/usecases/validate_host_signup_basics.dart';
import 'host_onboarding_progress_controller.dart';
import 'host_signup_api_providers.dart';

part 'host_signup_controller.g.dart';

class HostSignupFormState {
  const HostSignupFormState({
    this.draft = const HostSignupDraft(),
    this.fieldErrors = const {},
    this.isSubmitting = false,
    this.submitError,
  });

  final HostSignupDraft draft;
  final Map<String, String> fieldErrors;
  final bool isSubmitting;

  /// Set when the signup API call itself fails (network/server), as
  /// opposed to [fieldErrors] which come from client-side validation.
  final String? submitError;

  HostSignupFormState copyWith({
    HostSignupDraft? draft,
    Map<String, String>? fieldErrors,
    bool? isSubmitting,
    String? submitError,
  }) {
    return HostSignupFormState(
      draft: draft ?? this.draft,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
    );
  }
}

/// Holds the H-01 signup form draft, validates it, and submits it to the
/// signup API on continue. Screen-scoped (autoDispose): the draft only
/// needs to live for the duration of this step.
@riverpod
class HostSignupController extends _$HostSignupController {
  static const _validate = ValidateHostSignupBasicsUseCase();

  @override
  HostSignupFormState build() => const HostSignupFormState();

  void updateBusinessName(String value) {
    state = state.copyWith(draft: state.draft.copyWith(businessName: value));
  }

  void updateContactPhone(String value) {
    state = state.copyWith(draft: state.draft.copyWith(contactPhone: value));
  }

  void updateContactEmail(String value) {
    state = state.copyWith(draft: state.draft.copyWith(contactEmail: value));
  }

  void updateCity(City city) {
    state = state.copyWith(
      draft: state.draft.copyWith(city: city.name, cityId: city.id),
    );
  }

  /// Validates the draft, then submits it to the signup API. Returns true
  /// once the account is created and the wizard can advance to H-02 ·
  /// Host type. On a validation failure, [HostSignupFormState.fieldErrors]
  /// is populated; on an API failure, [HostSignupFormState.submitError] is.
  Future<bool> submit() async {
    final result = _validate(state.draft);
    final validated = result.when(
      ok: (draft) => draft,
      err: (failure) {
        final fieldErrors = failure is HostSignupValidationFailure
            ? failure.fieldErrors
            : const <String, String>{};
        state = state.copyWith(fieldErrors: fieldErrors, submitError: null);
        return null;
      },
    );
    if (validated == null) return false;

    state = state.copyWith(
      isSubmitting: true,
      fieldErrors: const {},
      submitError: null,
    );

    final useCase = ref.read(signupHostUseCaseProvider);
    final signupResult = await useCase(validated);
    return signupResult.when(
      ok: (result) {
        ref
            .read(hostSessionControllerProvider.notifier)
            .setSession(
              HostSession(
                accessToken: result.accessToken,
                userId: result.userId,
                accountStatus: result.accountStatus,
                businessName: validated.businessName,
              ),
            );
        // Seeds the resumable wizard step now, before the user has made
        // any H-02 choice, so a restart before then still resumes at
        // H-02 instead of falling back to H-05 Home for lack of a row.
        ref
            .read(hostOnboardingProgressControllerProvider.notifier)
            .setStep(HostOnboardingStep.hostType);
        state = state.copyWith(draft: validated, isSubmitting: false);
        return true;
      },
      err: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: failure.message,
        );
        return false;
      },
    );
  }
}
