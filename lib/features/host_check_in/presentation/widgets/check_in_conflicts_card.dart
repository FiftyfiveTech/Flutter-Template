import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../domain/entities/check_in_conflict.dart';
import 'check_in_copy.dart';

/// Offline check-ins the server rejected on sync. Read-only by design:
/// check-in is the sole gate into matching, so there's no override here.
class CheckInConflictsCard extends StatelessWidget {
  const CheckInConflictsCard({
    super.key,
    required this.conflicts,
    required this.onDismiss,
  });

  final List<CheckInConflict> conflicts;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return AhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sync_problem,
                size: 20,
                color: AppColors.statusError,
              ),
              AppSpacing.spacerSm,
              Expanded(
                child: Text(
                  conflicts.length == 1
                      ? '1 offline check-in was rejected'
                      : '${conflicts.length} offline check-ins were rejected',
                  style: typography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          AppSpacing.spacerXs,
          Text(
            "These guests don't count as checked in, so they won't be in "
            "tonight's matching.",
            style: typography.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          for (final conflict in conflicts) ...[
            const Divider(
              height: AppSpacing.lg,
              color: AppColors.borderDefault,
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.attendeeName ?? 'Unknown ticket',
                        style: typography.body,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _detail(conflict),
                        style: typography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () => onDismiss(conflict.scanId),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _detail(CheckInConflict conflict) {
    final scanned = 'Scanned ${formatCheckInTime(conflict.scannedAt)}';
    final winning = conflict.winningScannedAt;
    final reason = conflictReason(conflict.outcome);
    return winning != null
        ? '$scanned · $reason at ${formatCheckInTime(winning)}'
        : '$scanned · $reason';
  }
}
