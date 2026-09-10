import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/validate_phone_number.dart';
import 'host_login_api_providers.dart';

part 'phone_entry_controller.g.dart';

class PhoneEntryState {
  const PhoneEntryState({
    this.phoneNumber = '',
    this.fieldErrors = const {},
    this.isSubmitting = false,
    this.submitError,
  });

  final String phoneNumber;
  final Map<String, String> fieldErrors;
  final bool isSubmitting;

  /// Set when the OTP request API itself fails (network/server), as
  /// opposed to [fieldErrors] which come from client-side validation.
  final String? submitError;

  PhoneEntryState copyWith({
    String? phoneNumber,
    Map<String, String>? fieldErrors,
    bool? isSubmitting,
    String? submitError,
  }) {
    return PhoneEntryState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
    );
  }
}

/// Holds the login phone number, validates it, and requests an OTP for it.
/// Screen-scoped (autoDispose): only needs to live for this step.
@riverpod
class PhoneEntryController extends _$PhoneEntryController {
  static const _validate = ValidatePhoneNumberUseCase();

  @override
  PhoneEntryState build() => const PhoneEntryState();

  void updatePhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value);
  }

  /// Validates the phone number, then requests an OTP for it. Returns the
  /// normalized phone number once the OTP has been sent successfully, so
  /// the caller can navigate to the OTP-entry screen with it. On a
  /// validation failure, [PhoneEntryState.fieldErrors] is populated; on an
  /// API failure, [PhoneEntryState.submitError] is.
  Future<String?> submit() async {
    final result = _validate(state.phoneNumber);
    final validated = result.when(
      ok: (phone) => phone,
      err: (failure) {
        final fieldErrors = failure is PhoneValidationFailure
            ? failure.fieldErrors
            : const <String, String>{};
        state = state.copyWith(fieldErrors: fieldErrors, submitError: null);
        return null;
      },
    );
    if (validated == null) return null;

    state = state.copyWith(
      isSubmitting: true,
      fieldErrors: const {},
      submitError: null,
    );

    final useCase = ref.read(requestOtpUseCaseProvider);
    final otpResult = await useCase(validated);
    return otpResult.when(
      ok: (_) {
        state = state.copyWith(phoneNumber: validated, isSubmitting: false);
        return validated;
      },
      err: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: failure.message,
        );
        return null;
      },
    );
  }
}
