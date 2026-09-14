import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A row of tappable, wrapping multi-select chips — used for "pick any of
/// these tags" fields (e.g. event types a venue can host) where a
/// dropdown/checklist would be overkill.
class AhChipSelect extends StatelessWidget {
  const AhChipSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          _Chip(
            label: option,
            isSelected: selected.contains(option),
            typography: typography,
            onTap: () => onToggle(option),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.typography,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final AppTypography typography;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.actionPrimary.withValues(alpha: 0.16)
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: isSelected
                  ? AppColors.actionPrimary
                  : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            style: typography.bodySm.copyWith(
              color: isSelected
                  ? AppColors.actionPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
