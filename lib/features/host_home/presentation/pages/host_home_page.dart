import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/host_home_nav_card.dart';

/// H-05 · Home — the placeholder hub a host lands on once onboarding
/// completes. Nav destinations are stubs until their own features (event
/// creation, night ops, payouts) exist.
class HostHomePage extends StatelessWidget {
  const HostHomePage({super.key});

  void _showComingSoon(BuildContext context, String destination) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$destination — coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Home', style: typography.h3),
      ),
      body: SafeArea(
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
              Text("You're in", style: typography.h2),
              AppSpacing.spacerSm,
              Text(
                "We'll bring your events, night ops and payouts here next.",
                style: typography.body.copyWith(color: AppColors.textSecondary),
              ),
              AppSpacing.spacerLg,
              HostHomeNavCard(
                icon: Icons.event_outlined,
                label: 'Events',
                description: 'Create and manage your listings.',
                onTap: () => _showComingSoon(context, 'Events'),
              ),
              AppSpacing.spacerMd,
              HostHomeNavCard(
                icon: Icons.nightlife_outlined,
                label: 'Night ops',
                description: 'Live dashboard and door scanning.',
                onTap: () => _showComingSoon(context, 'Night ops'),
              ),
              AppSpacing.spacerMd,
              HostHomeNavCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Payouts',
                description: "Track what you've earned per event.",
                onTap: () => _showComingSoon(context, 'Payouts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
