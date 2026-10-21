import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Tone options mirroring the design system's `AlertBanner` component.
enum AhBannerTone { info, warning, error, success }

/// An inline banner for a rule/status the user must notice — a scoping
/// note, an expiry warning, a lapsed-document block.
class AhAlertBanner extends StatelessWidget {
  const AhAlertBanner({
    super.key,
    required this.message,
    this.tone = AhBannerTone.info,
  });

  final String message;
  final AhBannerTone tone;

  Color _colorIn(AppColors colors) => switch (tone) {
    AhBannerTone.info => colors.statusInfo,
    AhBannerTone.warning => colors.statusWarning,
    AhBannerTone.error => colors.statusError,
    AhBannerTone.success => colors.statusSuccess,
  };

  IconData get _icon => switch (tone) {
    AhBannerTone.info => Icons.info_outline,
    AhBannerTone.warning => Icons.warning_amber_outlined,
    AhBannerTone.error => Icons.error_outline,
    AhBannerTone.success => Icons.check_circle_outline,
  };

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final color = _colorIn(context.colors);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 20, color: color),
          AppSpacing.spacerSm,
          Expanded(
            child: Text(
              message,
              style: typography.bodySm.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
