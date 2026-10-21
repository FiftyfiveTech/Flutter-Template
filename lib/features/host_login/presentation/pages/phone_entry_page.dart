import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../controllers/phone_entry_controller.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';

/// Login · Phone entry — the first step of the "I already have an account"
/// flow from H-00 · Landing. Requests an OTP for the entered phone number,
/// then hands off to Login · OTP entry.
class PhoneEntryPage extends ConsumerStatefulWidget {
  const PhoneEntryPage({super.key});

  @override
  ConsumerState<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends ConsumerState<PhoneEntryPage> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final notifier = ref.read(phoneEntryControllerProvider.notifier);
    final phoneNumber = await notifier.submit();
    if (phoneNumber == null) {
      final submitError = ref.read(phoneEntryControllerProvider).submitError;
      if (submitError != null && mounted) {
        showAhMessageSheet(
          context,
          message: submitError,
          tone: AhMessageTone.error,
        );
      }
      return;
    }
    if (!mounted) return;

    context.push('/auth/phone/otp', extra: phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(phoneEntryControllerProvider);
    final notifier = ref.read(phoneEntryControllerProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Log in', style: typography.h3),
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
                      "Enter the phone number you signed up with. We'll text "
                      'you a one-time code.',
                      style: typography.body.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    AppSpacing.spacerLg,
                    AhTextField(
                      label: 'Phone number',
                      placeholder: '+91 98765 43210',
                      icon: Icons.call_outlined,
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                      onChanged: notifier.updatePhoneNumber,
                      errorText: state.fieldErrors['phoneNumber'],
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.colors.borderDefault),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm + AppSpacing.xs,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: AhButton(
                  label: state.isSubmitting ? 'Please wait…' : 'Send OTP',
                  fullWidth: true,
                  onPressed: state.isSubmitting ? null : _onContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
