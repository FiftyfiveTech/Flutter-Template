import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_async_search_field.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../../domain/entities/city.dart';
import '../controllers/city_search_providers.dart';
import '../controllers/host_signup_controller.dart';
import '../widgets/step_progress_dots.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';

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

  Future<void> _onContinue() async {
    final notifier = ref.read(hostSignupControllerProvider.notifier);
    final isValid = await notifier.submit();
    if (!isValid) {
      final submitError = ref.read(hostSignupControllerProvider).submitError;
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

    // pushReplacement, not push: signup is one-time (it mints the session
    // token), so once it succeeds the route must drop off the stack and
    // the back button/gesture must not be able to return here.
    context.pushReplacement('/host/signup/host-type');
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final formState = ref.watch(hostSignupControllerProvider);
    final notifier = ref.read(hostSignupControllerProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
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
                    AhAsyncSearchField<City>(
                      label: 'City',
                      value: formState.draft.city,
                      placeholder: 'Search for a city',
                      search: (query) =>
                          ref.read(citySearchResultsProvider(query).future),
                      displayStringForOption: (city) => city.name,
                      onSelected: notifier.updateCity,
                      errorText: formState.fieldErrors['city'],
                      searchOnEmptyQuery: true,
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
                  label: formState.isSubmitting ? 'Please wait…' : 'Continue',
                  fullWidth: true,
                  onPressed: formState.isSubmitting ? null : _onContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
