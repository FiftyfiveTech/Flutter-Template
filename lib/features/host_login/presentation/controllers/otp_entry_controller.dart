import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/session/host_session.dart';
import 'host_login_api_providers.dart';

part 'otp_entry_controller.g.dart';

class OtpEntryState {
  static const _sentinel = Object();

  const OtpEntryState({
    this.otp = '',
    this.isSubmitting = false,
    this.isResending = false,
    this.cooldownSeconds = 30,
    this.errorText,
  });

  final String otp;
  final bool isSubmitting;
  final bool isResending;
  final int cooldownSeconds;
  final String? errorText;

  bool get canResend => !isResending && cooldownSeconds == 0;

  OtpEntryState copyWith({
    String? otp,
    bool? isSubmitting,
    bool? isResending,
    int? cooldownSeconds,
    Object? errorText = _sentinel,
  }) {
    return OtpEntryState(
      otp: otp ?? this.otp,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isResending: isResending ?? this.isResending,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      errorText: identical(errorText, _sentinel)
          ? this.errorText
          : errorText as String?,
    );
  }
}

/// Holds the OTP entered for [phoneNumber], lets the host resend it, and
/// verifies it to sign the host in.
@riverpod
class OtpEntryController extends _$OtpEntryController {
  Timer? _timer;

  @override
  OtpEntryState build(String phoneNumber) {
    ref.onDispose(() {
      _timer?.cancel();
    });
    _startCooldown();
    return const OtpEntryState(cooldownSeconds: 30);
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.cooldownSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: state.cooldownSeconds - 1);
      }
    });
  }

  void updateOtp(String value) {
    state = state.copyWith(otp: value, errorText: null);
  }

  Future<void> resend() async {
    if (!state.canResend) return;

    state = state.copyWith(isResending: true, errorText: null);
    final useCase = ref.read(requestOtpUseCaseProvider);
    final result = await useCase(phoneNumber);
    result.when(
      ok: (_) {
        state = state.copyWith(isResending: false, cooldownSeconds: 30);
        _startCooldown();
      },
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
