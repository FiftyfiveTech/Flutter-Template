import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A star + one-decimal average rating (e.g. "★ 4.6"), with an optional
/// [label] ("Event rating", "Host rating"). Renders nothing when [rating]
/// is null — an unrated item shows no badge rather than a fake "0.0".
class AhRatingBadge extends StatelessWidget {
  const AhRatingBadge({
    super.key,
    required this.rating,
    this.label,
    this.color,
    this.showMax = false,
  });

  final double? rating;
  final String? label;

  /// Appends "/5" (e.g. "4.6/5").
  final bool showMax;

  /// Defaults to the secondary text colour (e.g. muted on ended cards).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final value = rating;
    if (value == null) return const SizedBox.shrink();
    final typography = Theme.of(context).extension<AppTypography>()!;
    final text = value.toStringAsFixed(1) + (showMax ? '/5' : '');
    final textColor = color ?? context.colors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 16, color: context.colors.statusWarning),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label == null ? text : '$label $text',
          style: typography.caption.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
