import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_avatar.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../domain/entities/check_in_result.dart';
import 'check_in_copy.dart';

/// The large valid / already-used / invalid card shown over the scanner
/// (and after a manual check-in). Colour-coded so the host can read it
/// from arm's length.
class CheckInResultCard extends StatelessWidget {
  const CheckInResultCard({
    super.key,
    required this.result,
    required this.onDismiss,
    this.onQueueForVerification,
    this.isBusy = false,
  });

  final CheckInResult result;
  final VoidCallback onDismiss;

  /// Shown only for offline scans that couldn't be verified locally.
  final VoidCallback? onQueueForVerification;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final copy = CheckInOutcomeCopy.forResult(result);
    final color = copy.tone.color;
    final name = result.attendeeName;
    final canQueue =
        onQueueForVerification != null &&
        result.outcome.canQueueForVerification;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSheet),
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(copy.tone.icon, color: color, size: AppSpacing.xxl),
              AppSpacing.spacerMd,
              Expanded(
                child: Text(
                  copy.title,
                  style: typography.h2.copyWith(color: color),
                ),
              ),
            ],
          ),
          if (name != null && name.isNotEmpty) ...[
            AppSpacing.spacerMd,
            Row(
              children: [
                AhAvatar(
                  name: name,
                  photoUrl: result.photoUrl,
                  radius: AppSpacing.xl,
                ),
                AppSpacing.spacerMd,
                Expanded(child: Text(name, style: typography.h3)),
              ],
            ),
          ],
          AppSpacing.spacerMd,
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              copy.detail,
              style: typography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (result.isOffline && result.outcome.isAdmitted) ...[
            AppSpacing.spacerSm,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Offline check-in',
                style: typography.caption.copyWith(
                  color: AppColors.statusWarning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          AppSpacing.spacerLg,
          if (canQueue) ...[
            AhButton(
              label: 'Let in, verify when back online',
              variant: AhButtonVariant.secondary,
              fullWidth: true,
              onPressed: isBusy ? null : onQueueForVerification,
            ),
            AppSpacing.spacerSm,
          ],
          AhButton(
            label: result.outcome.isAdmitted ? 'Next guest' : 'Dismiss',
            fullWidth: true,
            onPressed: isBusy ? null : onDismiss,
          ),
        ],
      ),
    );
  }
}
