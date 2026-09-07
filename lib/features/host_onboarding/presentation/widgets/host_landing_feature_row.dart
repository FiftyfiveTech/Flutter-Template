import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class HostLandingFeatureRow extends StatelessWidget {
  const HostLandingFeatureRow({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Semantics(
      label: label,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.trustVerified),
          AppSpacing.spacerSm,
          Expanded(
            child: Text(
              label,
              style: typography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
