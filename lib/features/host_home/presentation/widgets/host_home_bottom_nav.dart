import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class HostHomeBottomNav extends StatelessWidget {
  const HostHomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.sm,
        ),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                label: 'Home',
                icon: Icons.local_bar_rounded,
                onTap: () => onTap(0),
                typography: typography,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                label: 'Payouts',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => onTap(1),
                typography: typography,
              ),
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                label: 'Profile',
                icon: Icons.person_outline,
                onTap: () => onTap(2),
                typography: typography,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.typography,
  });

  final int index;
  final int currentIndex;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    if (isSelected) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.actionPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.actionPrimaryFg),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: typography.bodySm.copyWith(
                  color: AppColors.actionPrimaryFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Icon(icon, size: 22, color: AppColors.textSecondary),
      ),
    );
  }
}
