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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(hostVenuesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Venues', style: typography.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.isLoading && state.venues.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.actionPrimary,
                      ),
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
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.spacerMd,
                        for (final venue in state.venues) ...[
                          _VenueRow(
                            venue: venue,
                            onTap: () => context.push(
                              '/host/venues/${venue.id}',
                              extra: venue,
                            ),
                          ),
                          AppSpacing.spacerSm,
                        ],
                      ],
                    ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderDefault)),
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
                  onPressed: () => context.push('/host/venues/add'),
                ),
              ),
            ),
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
          const Icon(
            Icons.storefront_outlined,
            size: 20,
            color: AppColors.actionPrimary,
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
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
