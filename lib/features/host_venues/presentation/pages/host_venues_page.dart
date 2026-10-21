import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../domain/entities/host_venue.dart';
import '../controllers/host_venues_controller.dart';

/// H-06 · Venues — the host's saved venues, filled in automatically as
/// events are created at them. Tapping a row opens H-07 in edit mode;
/// "+ Add a venue" opens the same form in H-E0 add mode.
class HostVenuesPage extends ConsumerWidget {
  const HostVenuesPage({super.key});

  /// The add/edit form (H-07/H-E0) doesn't share this screen's provider —
  /// it pops back here on save without this list knowing anything changed.
  /// Re-fetch once the pushed route returns, whether it saved, deleted, or
  /// was just backed out of; a redundant refresh is harmless.
  Future<void> _pushAndRefresh(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    await context.push(path);
    if (!context.mounted) return;
    ref.read(hostVenuesControllerProvider.notifier).loadVenues();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(hostVenuesControllerProvider);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Venues', style: typography.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.isLoading && state.venues.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colors.actionPrimary,
                      ),
                    )
                  : state.errorMessage != null && state.venues.isEmpty
                  ? _LoadErrorView(
                      message: state.errorMessage!,
                      onRetry: () => ref
                          .read(hostVenuesControllerProvider.notifier)
                          .loadVenues(),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.md,
                        AppSpacing.gutter,
                        AppSpacing.lg,
                      ),
                      children: [
                        Text(
                          'Saved venues fill in automatically when you '
                          'create an event there.',
                          style: typography.bodySm.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        AppSpacing.spacerMd,
                        for (final venue in state.venues) ...[
                          _VenueRow(
                            venue: venue,
                            onTap: () => _pushAndRefresh(
                              context,
                              ref,
                              '/host/venues/${venue.id}',
                            ),
                          ),
                          AppSpacing.spacerSm,
                        ],
                      ],
                    ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.colors.borderDefault),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm + AppSpacing.xs,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: AhButton(
                  label: '+ Add a venue',
                  fullWidth: true,
                  onPressed: () =>
                      _pushAndRefresh(context, ref, '/host/venues/add'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load your venues",
              style: typography.h3,
              textAlign: TextAlign.center,
            ),
            AppSpacing.spacerSm,
            Text(
              message,
              style: typography.bodySm.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.spacerMd,
            AhButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _VenueRow extends StatelessWidget {
  const _VenueRow({required this.venue, required this.onTap});

  final HostVenue venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return AhCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 20,
            color: context.colors.actionPrimary,
          ),
          AppSpacing.spacerMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: typography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  venue.address,
                  style: typography.bodySm.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: context.colors.textTertiary,
          ),
        ],
      ),
    );
  }
}
