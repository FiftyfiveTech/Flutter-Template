import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/host_signup_draft.dart';
import '../../domain/usecases/validate_host_signup_basics.dart';

part 'host_signup_controller.g.dart';

class HostSignupFormState {
  const HostSignupFormState({
    this.draft = const HostSignupDraft(),
    this.fieldErrors = const {},
  });

  final HostSignupDraft draft;
  final Map<String, String> fieldErrors;

  HostSignupFormState copyWith({
    HostSignupDraft? draft,
    Map<String, String>? fieldErrors,
  }) {
    return HostSignupFormState(
      draft: draft ?? this.draft,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

/// Holds the H-01 signup form draft and validates it on submit. Screen-scoped
/// (autoDispose): the draft only needs to live for the duration of this step.
@riverpod
class HostSignupController extends _$HostSignupController {
  static const _useCase = ValidateHostSignupBasicsUseCase();

  @override
  HostSignupFormState build() =>
      const HostSignupFormState(draft: HostSignupDraft(city: 'Bangalore'));

  void updateBusinessName(String value) {
    state = state.copyWith(draft: state.draft.copyWith(businessName: value));
  }

  void updateContactPhone(String value) {
    state = state.copyWith(draft: state.draft.copyWith(contactPhone: value));
  }

  void updateContactEmail(String value) {
    state = state.copyWith(draft: state.draft.copyWith(contactEmail: value));
  }

  void updateCity(String value) {
    state = state.copyWith(draft: state.draft.copyWith(city: value));
  }

  /// Validates the draft. Returns true (and clears field errors) when the
  /// step is complete and the wizard can advance to H-02 · Host type.
  bool submit() {
    final result = _useCase(state.draft);
    return result.when(
      ok: (validated) {
        state = state.copyWith(draft: validated, fieldErrors: const {});
        return true;
      },
      err: (failure) {
        final fieldErrors = failure is HostSignupValidationFailure
            ? failure.fieldErrors
            : const <String, String>{};
        state = state.copyWith(fieldErrors: fieldErrors);
        return false;
      },
    );
  }
}
