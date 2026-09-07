import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The app's standard surface card — used for list rows, selectable
/// options and grouped content (event cards, venue rows, host-type
/// choices, document rows). Pass [onTap] to make it tappable and
/// [selected] to show the accent border used for chosen options.
class AhCard extends StatelessWidget {
  const AhCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppSpacing.radiusLg);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: borderRadius,
            border: Border.all(
              color: selected
                  ? AppColors.actionPrimary
                  : AppColors.borderDefault,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
