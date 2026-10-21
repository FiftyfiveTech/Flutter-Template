import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A labelled, integer-stepped slider, styled per the app's theme tokens.
class AhSlider extends StatelessWidget {
  const AhSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.valueLabel,
    this.helperText,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? valueLabel;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: typography.body),
            Text(
              valueLabel ?? '$value',
              style: typography.body.copyWith(
                color: context.colors.actionPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: context.colors.actionPrimary,
            thumbColor: context.colors.actionPrimary,
            inactiveTrackColor: context.colors.actionPrimary.withValues(
              alpha: 0.2,
            ),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              helperText!,
              style: typography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
