import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/host_home_event.dart';

class HostHomeEventCard extends StatelessWidget {
  const HostHomeEventCard({super.key, required this.event, this.onTap});

  final HostHomeEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final borderRadius = BorderRadius.circular(AppSpacing.radiusCard);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
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
                    style: typography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                event.formattedSchedule,
                style: typography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
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

    final (label, icon, color, bgColor) = switch (status) {
      HostEventStatus.upcoming => (
        'Upcoming',
        Icons.schedule,
        AppColors.statusInfo,
        AppColors.statusInfo.withValues(alpha: 0.16),
      ),
      HostEventStatus.draft => (
        'Draft',
        Icons.edit_note,
        AppColors.textSecondary,
        AppColors.textSecondary.withValues(alpha: 0.16),
      ),
      HostEventStatus.completed => (
        'Completed',
        Icons.check_circle_outline,
        AppColors.statusSuccess,
        AppColors.statusSuccess.withValues(alpha: 0.16),
      ),
    };

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
