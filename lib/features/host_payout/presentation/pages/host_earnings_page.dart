import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/rupee_format.dart';
import '../../../../shared/widgets/ah_alert_banner.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../controllers/host_earnings_controller.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Earnings — total paid out so far and this month's expected payout, with
/// a note that the expected figure is an estimate.
class HostEarningsPage extends ConsumerWidget {
  const HostEarningsPage({super.key});

  /// Shown under the expected payout — it is only settled after the event.
  static const disclaimer =
      'Expected payout may vary depending on ticket cancellations and '
      'refunds. The final amount is confirmed after the event.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(hostEarningsControllerProvider);
    final earnings = state.earnings;
    final now = DateTime.now();
    final hasEstimate = (earnings?.expectedGrossPaise ?? 0) > 0;

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Earnings', style: typography.h3),
      ),
      body: SafeArea(
        child: state.isLoading && earnings == null
            ? Center(
                child: CircularProgressIndicator(
                  color: context.colors.actionPrimary,
                ),
              )
            : earnings == null
            ? _ErrorView(
                message: state.errorMessage ?? "Couldn't load your earnings.",
                onRetry: () =>
                    ref.read(hostEarningsControllerProvider.notifier).load(),
              )
            : RefreshIndicator(
                color: context.colors.actionPrimary,
                onRefresh: () =>
                    ref.read(hostEarningsControllerProvider.notifier).load(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  children: [
                    AhCard(
                      child: _AmountBlock(
                        label: 'Total payout received',
                        amount: formatRupees(earnings.totalNetPayoutPaise),
                        caption: earnings.settledEventsCount == 0
                            ? 'No payouts yet'
                            : 'Paid out across ${earnings.settledEventsCount} '
                                  '${earnings.settledEventsCount == 1 ? 'event' : 'events'}',
                        large: true,
                      ),
                    ),
                    AppSpacing.spacerMd,
                    AhCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AmountBlock(
                            label:
                                '${earnings.isExpectedConfirmed ? 'Payout this month' : 'Expected this month'}'
                                ' · ${_months[now.month - 1]} ${now.year}',
                            amount: formatRupees(
                              earnings.isExpectedConfirmed
                                  ? earnings.expectedNetPayoutPaise
                                  : earnings.expectedGrossPaise,
                            ),
                            tag: earnings.isExpectedConfirmed
                                ? 'Confirmed'
                                : hasEstimate
                                ? 'Estimate'
                                : null,
                            caption: earnings.unsettledBookingsCount == 0
                                ? 'No unsettled bookings'
                                : 'From ${earnings.unsettledBookingsCount} '
                                      '${earnings.unsettledBookingsCount == 1 ? 'booking' : 'bookings'}'
                                      ' awaiting settlement',
                          ),
                          if (!earnings.isExpectedConfirmed && hasEstimate) ...[
                            AppSpacing.spacerMd,
                            const AhAlertBanner(message: disclaimer),
                          ],
                        ],
                      ),
                    ),
                    AppSpacing.spacerMd,
                    if (state.account.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: AhAlertBanner(
                          tone: AhBannerTone.warning,
                          message:
                              'Add a UPI ID or bank account so we know where to '
                              'send your payouts.',
                        ),
                      ),
                    AhButton(
                      label: !state.account.isEmpty
                          ? 'Edit payout details'
                          : 'Add payout details',
                      variant: AhButtonVariant.tertiary,
                      fullWidth: true,
                      onPressed: () async {
                        await context.push('/host/you/payout');
                        if (!context.mounted) return;
                        ref
                            .read(hostEarningsControllerProvider.notifier)
                            .load();
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({
    required this.label,
    required this.amount,
    required this.caption,
    this.tag,
    this.large = false,
  });

  final String label;
  final String amount;
  final String caption;
  final String? tag;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: typography.bodySm.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            if (tag != null)
              Text(
                tag!,
                style: typography.caption.copyWith(
                  color: context.colors.statusWarning,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        AppSpacing.spacerXs,
        Text(
          amount,
          style: (large ? typography.h1 : typography.h2).copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        AppSpacing.spacerXs,
        Text(
          caption,
          style: typography.caption.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
              message,
              textAlign: TextAlign.center,
              style: typography.body.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            AppSpacing.spacerMd,
            AhButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
