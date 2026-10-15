import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/check_in_controller.dart';
import 'check_in_copy.dart';

/// Online / offline status, and whether offline scans can be verified.
class CheckInConnectionPill extends StatelessWidget {
  const CheckInConnectionPill({super.key, required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final downloadedAt = state.manifestDownloadedAt;

    final (label, color) = switch (state.connection) {
      CheckInConnection.unknown => ('Connecting…', AppColors.textSecondary),
      CheckInConnection.online => ('Online', AppColors.statusSuccess),
      CheckInConnection.offline when downloadedAt == null => (
        'Offline · no guest list on this phone',
        AppColors.statusError,
      ),
      CheckInConnection.offline when state.isManifestExpired => (
        'Offline · guest list expired',
        AppColors.statusError,
      ),
      CheckInConnection.offline => (
        'Offline · guest list from ${formatCheckInTime(downloadedAt!)}',
        AppColors.statusWarning,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: typography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
