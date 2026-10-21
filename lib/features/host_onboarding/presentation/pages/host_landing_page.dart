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
      backgroundColor: context.colors.backgroundPrimary,
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
                    errorBuilder: (context, error, stackTrace) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colors.surfaceCard,
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
                          context.colors.backgroundPrimary.withValues(alpha: 0),
                          context.colors.backgroundPrimary,
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
                        color: context.colors.actionTertiaryFg,
                      ),
                    ),
                    AppSpacing.spacerSm,
                    Text(
                      "Fill the room. We'll hold the ratio.",
                      style: typography.h1,
                    ),
                    AppSpacing.spacerMd,
                    Text(
                      'List a night, set the price, let verified members book.',
                      style: typography.body.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const HostLandingFeatureRow(
                      icon: Icons.balance,
                      label: 'Ratio held automatically',
                    ),
                    AppSpacing.spacerMd,
                    const HostLandingFeatureRow(
                      icon: Icons.verified_user,
                      label: 'ID-verified attendees',
                    ),
                    AppSpacing.spacerMd,
                    const HostLandingFeatureRow(
                      icon: Icons.qr_code_scanner,
                      label: 'Offline-capable door scanning',
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
                    onPressed: () => context.push('/auth/phone'),
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
