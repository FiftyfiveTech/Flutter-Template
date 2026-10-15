import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_alert_banner.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';
import '../../../../shared/widgets/ah_shimmer.dart';
import '../controllers/check_in_controller.dart';
import '../widgets/check_in_conflicts_card.dart';
import '../widgets/check_in_connection_pill.dart';

/// HOST-OPS · Door check-in hub for one event: live count, connection and
/// offline-readiness status, pending sync, and the way into the scanner
/// and guest list. Opening it downloads the offline guest list.
class CheckInHubPage extends ConsumerWidget {
  const CheckInHubPage({super.key, required this.eventId, this.eventTitle});

  final String eventId;
  final String? eventTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final provider = checkInControllerProvider(eventId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(eventTitle ?? 'Check-in', style: typography.h3),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.actionPrimary,
          onRefresh: notifier.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.lg,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CheckInConnectionPill(state: state),
              ),
              AppSpacing.spacerMd,
              _CountCard(state: state),
              if (state.loadErrorMessage != null &&
                  state.attendees.isEmpty) ...[
                AppSpacing.spacerMd,
                AhAlertBanner(
                  message:
                      "Couldn't load the guest list: "
                      '${state.loadErrorMessage}',
                  tone: AhBannerTone.error,
                ),
              ],
              if (state.connection == CheckInConnection.offline &&
                  (!state.hasManifest || state.isManifestExpired)) ...[
                AppSpacing.spacerMd,
                const AhAlertBanner(
                  message:
                      "Tickets can't be verified offline right now. "
                      'Reconnect for a moment to download a fresh guest '
                      'list, or search guests by name.',
                  tone: AhBannerTone.warning,
                ),
              ],
              if (state.pendingCount > 0) ...[
                AppSpacing.spacerMd,
                _PendingSyncCard(
                  pendingCount: state.pendingCount,
                  isSyncing: state.isSyncing,
                  onSync: () async {
                    final message = await notifier.syncNow();
                    if (!context.mounted || message.isEmpty) return;
                    await showAhMessageSheet(context, message: message);
                  },
                ),
              ],
              if (state.conflicts.isNotEmpty) ...[
                AppSpacing.spacerMd,
                CheckInConflictsCard(
                  conflicts: state.conflicts,
                  onDismiss: notifier.dismissConflict,
                ),
              ],
              AppSpacing.spacerLg,
              AhButton(
                label: 'Scan tickets',
                fullWidth: true,
                onPressed: () =>
                    context.push('/host/events/$eventId/check-in/scan'),
              ),
              AppSpacing.spacerSm,
              AhButton(
                label: 'Guest list',
                variant: AhButtonVariant.secondary,
                fullWidth: true,
                onPressed: () =>
                    context.push('/host/events/$eventId/check-in/guests'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final total = state.totalCount;
    final progress = total == 0 ? 0.0 : state.checkedInCount / total;

    return AhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checked in',
            style: typography.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.spacerXs,
          state.isLoading
              ? const AhShimmerBox(width: 120, height: AppSpacing.xxl)
              : Text(
                  '${state.checkedInCount} / $total',
                  style: typography.display,
                ),
          AppSpacing.spacerSm,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: AppSpacing.sm,
              color: AppColors.statusSuccess,
              backgroundColor: AppColors.backgroundSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSyncCard extends StatelessWidget {
  const _PendingSyncCard({
    required this.pendingCount,
    required this.isSyncing,
    required this.onSync,
  });

  final int pendingCount;
  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return AhCard(
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 20,
            color: AppColors.statusWarning,
          ),
          AppSpacing.spacerSm,
          Expanded(
            child: Text(
              pendingCount == 1
                  ? '1 check-in waiting to sync'
                  : '$pendingCount check-ins waiting to sync',
              style: typography.body,
            ),
          ),
          isSyncing
              ? const SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.actionPrimary,
                  ),
                )
              : TextButton(onPressed: onSync, child: const Text('Sync now')),
        ],
      ),
    );
  }
}
