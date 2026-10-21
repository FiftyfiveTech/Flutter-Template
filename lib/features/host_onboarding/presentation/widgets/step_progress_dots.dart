import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// The step-progress indicator shown across the host signup wizard
/// (H-01–H-04): a row of dots plus a "Step X of Y" label.
class StepProgressDots extends StatelessWidget {
  const StepProgressDots({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      child: Row(
        children: [
          for (var step = 1; step <= totalSteps; step++) ...[
            Container(
              width: AppSpacing.sm,
              height: AppSpacing.sm,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step == currentStep
                    ? context.colors.actionPrimary
                    : context.colors.borderDefault,
              ),
            ),
            if (step != totalSteps) AppSpacing.spacerXs,
          ],
          AppSpacing.spacerSm,
          Text(
            'Step $currentStep of $totalSteps',
            style: typography.caption.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
