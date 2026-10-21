import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A labeled +/- stepper for a bounded integer value (e.g. venue max
/// capacity). Use instead of a free-text numeric field whenever the value
/// must stay within a known min/max/step range.
class AhStepperInput extends StatelessWidget {
  const AhStepperInput({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix,
    this.errorText,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.bodySm),
        AppSpacing.spacerXs,
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: hasError
                  ? context.colors.statusError
                  : context.colors.borderDefault,
            ),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: value - step >= min
                    ? () => onChanged(value - step)
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    suffix == null ? '$value' : '$value $suffix',
                    style: typography.body.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onTap: value + step <= max
                    ? () => onChanged(value + step)
                    : null,
              ),
            ],
          ),
        ),
        if (hasError) ...[
          AppSpacing.spacerXs,
          Text(
            errorText!,
            style: typography.caption.copyWith(
              color: context.colors.statusError,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? context.colors.actionPrimary
                : context.colors.textTertiary,
          ),
        ),
      ),
    );
  }
}
