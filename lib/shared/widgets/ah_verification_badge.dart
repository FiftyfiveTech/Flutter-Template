import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Tappable verification-status pill — badge styling (tinted fill, status
/// icon) with button affordances (border, chevron, ripple). Used in the
/// Home header and on You; both open H-04 · Verification on tap.
class AhVerificationBadge extends StatelessWidget {
  const AhVerificationBadge({
    super.key,
    required this.isVerified,
    required this.onTap,
  });

  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final color = isVerified
        ? AppColors.trustVerified
        : AppColors.statusWarning;

    return Semantics(
      button: true,
      label: isVerified ? 'Verified, view documents' : 'Verification pending',
      child: Material(
        color: color.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs + 2,
              AppSpacing.xs,
              AppSpacing.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.schedule,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isVerified ? 'Verified' : 'Pending',
                  style: typography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
