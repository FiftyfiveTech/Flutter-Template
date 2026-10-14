import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../../../shared/widgets/ah_shimmer.dart';
import '../../../../shared/widgets/ah_verification_badge.dart';
import '../controllers/host_home_controller.dart';
import '../widgets/host_home_bottom_nav.dart';
import '../widgets/host_home_event_card.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';

/// H-05 · Home — the main hub for hosts to manage their events,
/// venues, verification status, and operations.
class HostHomePage extends ConsumerWidget {
  const HostHomePage({super.key});

  void _showMessage(BuildContext context, String message) {
    showAhMessageSheet(context, message: message, tone: AhMessageTone.info);
  }

  /// Venues and events are managed on separate screens with their own
  /// providers — they pop back here without this screen knowing anything
  /// changed. Re-fetch the summary once the pushed route returns (saved,
  /// deleted, or just backed out of); a redundant refresh is harmless.
  Future<void> _pushAndRefresh(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    await context.push(path);
    if (!context.mounted) return;
    ref.read(hostHomeControllerProvider.notifier).loadSummary();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(hostHomeControllerProvider);
    final notifier = ref.read(hostHomeControllerProvider.notifier);

    final summary = state.summary;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.actionPrimary,
                backgroundColor: AppColors.surfaceCard,
                onRefresh: notifier.loadSummary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: Organization name + Add Event FAB
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              summary?.hostName ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: typography.h2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (summary != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            AhVerificationBadge(
                              isVerified: summary.isVerified,
                              onTap: () => _pushAndRefresh(
                                context,
                                ref,
                                '/host/verification',
                              ),
                            ),
                          ],
                          const SizedBox(width: AppSpacing.md),
                          _AddEventButton(
                            onTap: () => _pushAndRefresh(
                              context,
                              ref,
                              '/host/events/new',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Venues Card
                      if (summary != null) ...[
                        if (state.isLoadingDetails)
                          const _VenuesCardShimmer()
                        else
                          _VenuesCard(
                            count: summary.savedVenuesCount,
                            onTap: () =>
                                _pushAndRefresh(context, ref, '/host/venues'),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Section Header
                      Text(
                        'YOUR EVENTS — TAP TO EDIT',
                        style: typography.label.copyWith(
                          letterSpacing: 1.1,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Events List
                      if (state.isLoading && summary == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: CircularProgressIndicator(
                              color: AppColors.actionPrimary,
                            ),
                          ),
                        )
                      else if (state.isLoadingDetails) ...[
                        const _EventCardShimmer(),
                        const SizedBox(height: AppSpacing.cardGap),
                        const _EventCardShimmer(),
                      ] else if (summary != null && summary.events.isEmpty)
                        _NoEventsMessage(
                          onAddEvent: () =>
                              _pushAndRefresh(context, ref, '/host/events/new'),
                        )
                      else if (summary != null) ...[
                        for (final event in summary.events) ...[
                          HostHomeEventCard(
                            event: event,
                            onTap: () => _pushAndRefresh(
                              context,
                              ref,
                              '/host/events/${event.id}',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                        ],
                      ],
                      // Bottom padding so content is not hidden behind the floating nav bar
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HostHomeBottomNav(
        currentIndex: state.selectedTabIndex,
        onTap: (index) {
          if (index == 1) {
            _showMessage(context, 'Payouts — coming soon');
            return;
          }
          if (index == 2) {
            context.push('/host/you');
            return;
          }
          notifier.selectTab(index);
        },
      ),
    );
  }
}

class _NoEventsMessage extends StatelessWidget {
  const _NoEventsMessage({required this.onAddEvent});

  final VoidCallback onAddEvent;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return AhCard(
      onTap: onAddEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.event_note_outlined,
            size: 28,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No events yet',
            style: typography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap to list your first night.',
            style: typography.bodySm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AddEventButton extends StatelessWidget {
  const _AddEventButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.actionPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: AppColors.actionPrimaryFg,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _VenuesCardShimmer extends StatelessWidget {
  const _VenuesCardShimmer();

  @override
  Widget build(BuildContext context) {
    return const AhCard(
      child: Row(
        children: [
          AhShimmerBox(width: 20, height: 20),
          SizedBox(width: AppSpacing.sm + 2),
          Expanded(child: AhShimmerBox(height: 18)),
          SizedBox(width: AppSpacing.sm),
          AhShimmerBox(width: 18, height: 18),
        ],
      ),
    );
  }
}

class _EventCardShimmer extends StatelessWidget {
  const _EventCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AhShimmerBox(
                width: 72,
                height: 20,
                borderRadius: BorderRadius.all(
                  Radius.circular(AppSpacing.radiusPill),
                ),
              ),
              Spacer(),
              AhShimmerBox(width: 60, height: 14),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          AhShimmerBox(width: 180, height: 20),
          SizedBox(height: AppSpacing.xs),
          AhShimmerBox(width: 140, height: 14),
        ],
      ),
    );
  }
}

class _VenuesCard extends StatelessWidget {
  const _VenuesCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return AhCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              count == 0 ? 'No venues yet — Add one' : 'Venues · $count saved',
              style: typography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
