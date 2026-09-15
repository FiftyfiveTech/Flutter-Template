import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A horizontal two-tone bar showing the male/female split of seats sold,
/// matching the design system's `RatioMeter` component. This is a static
/// preview (no sales-state colouring, no numbers) — the richer
/// warning/breach states described alongside it apply once real sales
/// exist, which is out of scope for a brand-new, zero-sale event.
class AhRatioMeter extends StatelessWidget {
  const AhRatioMeter({super.key, this.malePct = 50});

  /// Percentage (0-100) of the bar rendered in the "male" tone.
  final double malePct;

  @override
  Widget build(BuildContext context) {
    final maleFraction = (malePct / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            Expanded(
              flex: (maleFraction * 1000).round(),
              child: Container(color: AppColors.actionTertiaryFg),
            ),
            Expanded(
              flex: ((1 - maleFraction) * 1000).round(),
              child: Container(color: AppColors.actionPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
