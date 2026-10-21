import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Tone options mirroring the design system's `Badge` component.
enum AhTone { trust, success, warning, error, info, accent }

/// A small status pill — verification badges, document upload status,
/// host-type tags. Derives a soft background from the tone's solid color
/// rather than inventing a new token.
class AhBadge extends StatelessWidget {
  const AhBadge({super.key, required this.label, this.tone = AhTone.accent});

  final String label;
  final AhTone tone;

  Color _colorFor(AhTone tone, AppColors colors) => switch (tone) {
    AhTone.trust => colors.trustVerified,
    AhTone.success => colors.statusSuccess,
    AhTone.warning => colors.statusWarning,
    AhTone.error => colors.statusError,
    AhTone.info => colors.statusInfo,
    AhTone.accent => colors.actionPrimary,
  };

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final color = _colorFor(tone, context.colors);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: typography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
