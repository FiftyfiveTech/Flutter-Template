import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../widgets/host_landing_feature_row.dart';

/// H-00 · Landing — the first screen a prospective host sees, before signup.
class HostLandingPage extends StatelessWidget {
  const HostLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/host_landing_hero.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                          ),
                        ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 96,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.backgroundPrimary.withValues(alpha: 0),
                          AppColors.backgroundPrimary,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.lg,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOR HOSTS',
                      style: typography.label.copyWith(
                        color: AppColors.actionTertiaryFg,
                      ),
                    ),
                    AppSpacing.spacerSm,
                    Text(
                      "Fill the room. We'll hold the ratio.",
                      style: typography.h1,
                    ),
                    AppSpacing.spacerMd,
                    Text(
                      'List a night, set the price, and let verified members book. '
                      'We check IDs, hold the gender balance and scan the door — you run the room.',
                      style: typography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const HostLandingFeatureRow(
                      icon: Icons.balance,
                      label: 'Ratio held automatically, batch by batch',
                    ),
                    AppSpacing.spacerMd,
                    const HostLandingFeatureRow(
                      icon: Icons.verified_user,
                      label: 'Every attendee ID-verified before they can pay',
                    ),
                    AppSpacing.spacerMd,
                    const HostLandingFeatureRow(
                      icon: Icons.qr_code_scanner,
                      label: 'Door scanning, offline-capable',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  AhButton(
                    label: 'Become a host',
                    fullWidth: true,
                    onPressed: () => context.go('/host/signup'),
                  ),
                  AppSpacing.spacerSm,
                  AhButton(
                    label: 'I already have an account',
                    variant: AhButtonVariant.tertiary,
                    fullWidth: true,
                    onPressed: () => context.go('/auth/phone'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
