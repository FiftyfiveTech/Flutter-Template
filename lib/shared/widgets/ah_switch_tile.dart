import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A labeled toggle row matching the design system's `Switch` component —
/// label, optional description, and the switch itself in a surface card.
class AhSwitchTile extends StatelessWidget {
  const AhSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: context.colors.borderDefault),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: typography.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    AppSpacing.spacerXs,
                    Text(
                      description!,
                      style: typography.caption.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IgnorePointer(
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: context.colors.actionPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
