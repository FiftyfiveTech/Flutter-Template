import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/session/host_session.dart';
import 'host_login_api_providers.dart';

part 'otp_entry_controller.g.dart';

class OtpEntryState {
  const OtpEntryState({
    this.otp = '',
    this.isSubmitting = false,
    this.isResending = false,
    this.errorText,
  });

  final String otp;
  final bool isSubmitting;
  final bool isResending;
  final String? errorText;

  OtpEntryState copyWith({
    String? otp,
    bool? isSubmitting,
    bool? isResending,
    String? errorText,
  }) {
    return OtpEntryState(
      otp: otp ?? this.otp,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isResending: isResending ?? this.isResending,
      errorText: errorText,
    );
  }
}

/// Holds the OTP entered for [phoneNumber], lets the host resend it, and
/// verifies it to sign the host in.
@riverpod
class OtpEntryController extends _$OtpEntryController {
  @override
  OtpEntryState build(String phoneNumber) => const OtpEntryState();

  void updateOtp(String value) {
    state = state.copyWith(otp: value, errorText: null);
  }

  Future<void> resend() async {
    state = state.copyWith(isResending: true, errorText: null);
    final useCase = ref.read(requestOtpUseCaseProvider);
    final result = await useCase(phoneNumber);
    state = result.when(
      ok: (_) => state.copyWith(isResending: false),
      err: (failure) =>
          state.copyWith(isResending: false, errorText: failure.message),
    );
  }

  /// Verifies the entered code and, on success, signs the host in. Returns
  /// true once the session has been set and the caller can navigate on.
  Future<bool> submit() async {
    final code = state.otp.trim();
    if (code.length != 6) {
      state = state.copyWith(errorText: 'Enter the 6-digit code');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorText: null);

    final useCase = ref.read(verifyOtpUseCaseProvider);
    final result = await useCase(phoneNumber, code);
    return result.when(
      ok: (loginResult) {
        ref
            .read(hostSessionControllerProvider.notifier)
            .setSession(
              HostSession(
                accessToken: loginResult.accessToken,
                userId: loginResult.userId,
                accountStatus: loginResult.accountStatus,
              ),
            );
        state = state.copyWith(isSubmitting: false);
        return true;
      },
      err: (failure) {
        state = state.copyWith(isSubmitting: false, errorText: failure.message);
        return false;
      },
    );
  }
}
