import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_search_field.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../controllers/host_signup_controller.dart';
import '../widgets/step_progress_dots.dart';

/// H-01 · Signup — the first step of the host onboarding wizard. Collects
/// business/organiser basics; host type (H-02) decides the document set.
class HostSignupPage extends ConsumerStatefulWidget {
  const HostSignupPage({super.key});

  @override
  ConsumerState<HostSignupPage> createState() => _HostSignupPageState();
}

class _HostSignupPageState extends ConsumerState<HostSignupPage> {
  final _businessNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final notifier = ref.read(hostSignupControllerProvider.notifier);
    final isValid = notifier.submit();
    if (!isValid) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Host type — coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final formState = ref.watch(hostSignupControllerProvider);
    final notifier = ref.read(hostSignupControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Host signup', style: typography.h3),
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
                    const StepProgressDots(currentStep: 1, totalSteps: 4),
                    AppSpacing.spacerMd,
                    Text(
                      "Tell us who's hosting. We'll ask for documents next, "
                      'based on what kind of host you are.',
                      style: typography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.spacerLg,
                    AhTextField(
                      label: 'Business or organiser name',
                      placeholder: 'e.g. Cellar Door Collective',
                      controller: _businessNameController,
                      onChanged: notifier.updateBusinessName,
                      errorText: formState.fieldErrors['businessName'],
                    ),
                    AppSpacing.spacerMd,
                    AhTextField(
                      label: 'Contact phone',
                      placeholder: '+91 98765 43210',
                      icon: Icons.call_outlined,
                      keyboardType: TextInputType.phone,
                      controller: _contactPhoneController,
                      onChanged: notifier.updateContactPhone,
                      errorText: formState.fieldErrors['contactPhone'],
                    ),
                    AppSpacing.spacerMd,
                    AhTextField(
                      label: 'Contact email',
                      placeholder: 'you@business.com',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      controller: _contactEmailController,
                      onChanged: notifier.updateContactEmail,
                      errorText: formState.fieldErrors['contactEmail'],
                    ),
                    AppSpacing.spacerMd,
                    AhSearchField(
                      label: 'City',
                      value: formState.draft.city,
                      placeholder: 'Search for a city',
                      options: const ['Bangalore'],
                      onSelected: notifier.updateCity,
                      errorText: formState.fieldErrors['city'],
                    ),
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
                  label: 'Continue',
                  fullWidth: true,
                  onPressed: _onContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
