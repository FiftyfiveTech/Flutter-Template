import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_alert_banner.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../controllers/otp_entry_controller.dart';

/// Login · OTP entry — the second step of the "I already have an account"
/// flow. Verifies the code against the OTP-verify API and, on success,
/// signs the host in.
class OtpEntryPage extends ConsumerStatefulWidget {
  const OtpEntryPage({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<OtpEntryPage> createState() => _OtpEntryPageState();
}

class _OtpEntryPageState extends ConsumerState<OtpEntryPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    final notifier = ref.read(
      otpEntryControllerProvider(widget.phoneNumber).notifier,
    );
    final success = await notifier.submit();
    if (success && mounted) {
      // go, not push: login mints the session token, so once it succeeds
      // the auth route stack must not be reachable via back button/gesture.
      context.go('/host/home');
    }
  }

  Future<void> _onResend() async {
    final notifier = ref.read(
      otpEntryControllerProvider(widget.phoneNumber).notifier,
    );
    await notifier.resend();
    final errorText = ref
        .read(otpEntryControllerProvider(widget.phoneNumber))
        .errorText;
    if (errorText == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Code resent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(otpEntryControllerProvider(widget.phoneNumber));
    final notifier = ref.read(
      otpEntryControllerProvider(widget.phoneNumber).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Enter code', style: typography.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.md,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the 6-digit code sent to ${widget.phoneNumber}.',
                      style: typography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.spacerLg,
                    AhTextField(
                      label: 'One-time code',
                      placeholder: '••••••',
                      icon: Icons.lock_outline,
                      keyboardType: TextInputType.number,
                      controller: _otpController,
                      onChanged: notifier.updateOtp,
                      errorText: state.errorText,
                    ),
                    AppSpacing.spacerMd,
                    AhButton(
                      label: state.isResending
                          ? 'Resending…'
                          : state.cooldownSeconds > 0
                          ? 'Resend in ${state.cooldownSeconds}s'
                          : "Didn't get it? Resend",
                      variant: AhButtonVariant.tertiary,
                      onPressed: state.canResend ? _onResend : null,
                    ),
                    if (state.errorText != null) ...[
                      AppSpacing.spacerSm,
                      AhAlertBanner(
                        message: state.errorText!,
                        tone: AhBannerTone.error,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderDefault)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm + AppSpacing.xs,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: AhButton(
                  label: state.isSubmitting ? 'Please wait…' : 'Verify',
                  fullWidth: true,
                  onPressed: state.isSubmitting ? null : _onVerify,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
