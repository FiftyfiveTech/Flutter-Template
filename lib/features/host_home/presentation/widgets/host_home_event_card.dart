import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../domain/entities/host_home_event.dart';

class HostHomeEventCard extends StatelessWidget {
  const HostHomeEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onCheckIn,
  });

  final HostHomeEvent event;
  final VoidCallback? onTap;

  /// Shown as a "Check in guests" button when [HostHomeEvent.canCheckIn].
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final borderRadius = BorderRadius.circular(AppSpacing.radiusCard);
    // An ended event can't be acted on any more — the card is muted and
    // offers no actions; tapping it only opens the read-only details.
    final isEnded = event.status == HostEventStatus.completed;
    final primaryText = isEnded
        ? AppColors.textTertiary
        : AppColors.textPrimary;
    final secondaryText = isEnded
        ? AppColors.textTertiary
        : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isEnded
                ? AppColors.backgroundSecondary
                : AppColors.surfaceCard,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(status: event.status),
                  const Spacer(),
                  Text(
                    event.soldSummary,
                    style: typography.caption.copyWith(color: secondaryText),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                event.title,
                style: typography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                event.formattedSchedule,
                style: typography.caption.copyWith(color: secondaryText),
              ),
              if (!isEnded && event.canCheckIn && onCheckIn != null) ...[
                const SizedBox(height: AppSpacing.md),
                AhButton(
                  label: 'Check in guests',
                  fullWidth: true,
                  onPressed: onCheckIn,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final HostEventStatus status;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    final (label, icon, color) = switch (status) {
      HostEventStatus.draft => (
        'Draft',
        Icons.edit_note,
        AppColors.textSecondary,
      ),
      HostEventStatus.inReview => (
        'In review',
        Icons.hourglass_top,
        AppColors.statusWarning,
      ),
      HostEventStatus.upcoming => (
        'Upcoming',
        Icons.schedule,
        AppColors.statusInfo,
      ),
      HostEventStatus.live => ('Live', Icons.sensors, AppColors.actionPrimary),
      HostEventStatus.completed => (
        'Completed',
        Icons.check_circle_outline,
        AppColors.textTertiary,
      ),
      HostEventStatus.cancelled => (
        'Cancelled',
        Icons.cancel_outlined,
        AppColors.statusError,
      ),
    };
    final bgColor = color.withValues(alpha: 0.16);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: typography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
