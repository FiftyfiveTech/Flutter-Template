import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Button style variants mirroring the design system's `Button` component.
enum AhButtonVariant { primary, secondary, tertiary, destructive }

/// The app's standard button — primary (filled accent), secondary (filled
/// neutral) or tertiary (text-only). Used for every CTA across the app so
/// sizing/color/radius stay consistent without re-styling per screen.
class AhButton extends StatelessWidget {
  const AhButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AhButtonVariant.primary,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AhButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );

    final Widget button = switch (variant) {
      AhButtonVariant.primary => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionPrimary,
          foregroundColor: AppColors.actionPrimaryFg,
          disabledBackgroundColor: AppColors.actionPrimary.withValues(
            alpha: 0.4,
          ),
          shape: shape,
        ),
        child: Text(label),
      ),
      AhButtonVariant.secondary => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionSecondary,
          foregroundColor: AppColors.actionSecondaryFg,
          shape: shape,
        ),
        child: Text(label),
      ),
      AhButtonVariant.tertiary => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.actionTertiaryFg,
          shape: shape,
        ),
        child: Text(label),
      ),
      AhButtonVariant.destructive => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionDestructive,
          foregroundColor: AppColors.actionPrimaryFg,
          shape: shape,
        ),
        child: Text(label),
      ),
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppSpacing.touchTargetComfortable,
      child: button,
    );
  }
}
