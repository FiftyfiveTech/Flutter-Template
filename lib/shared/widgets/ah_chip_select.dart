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
    this.showRemoveIcon = false,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  /// Adds a trailing ✕ to selected chips — for showing just the picked
  /// values (e.g. under an `AhAsyncSearchField`), where tapping removes.
  final bool showRemoveIcon;

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
            showRemoveIcon: showRemoveIcon,
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
    required this.showRemoveIcon,
    required this.typography,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool showRemoveIcon;
  final AppTypography typography;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? context.colors.actionPrimary
        : context.colors.textSecondary;

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
                ? context.colors.actionPrimary.withValues(alpha: 0.16)
                : context.colors.surfaceCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: isSelected
                  ? context.colors.actionPrimary
                  : context.colors.borderDefault,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: typography.bodySm.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showRemoveIcon && isSelected) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.close,
                  size: 14,
                  color: textColor,
                  semanticLabel: 'Remove $label',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
