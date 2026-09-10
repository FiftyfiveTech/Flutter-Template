import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_alert_banner.dart';
import '../../../../shared/widgets/ah_badge.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../domain/entities/host_document_status.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_document_verification_status.dart';
import '../controllers/host_verification_status_controller.dart';

/// H-04 · Verification — shown once H-03 · Documents has been submitted
/// for review. Polls `GET /api/v1/host/documents` (on load and on
/// pull-to-refresh) for where each document stands; the account sits in
/// `pending_review` until every document is verified
/// (`docs/features/11-admin-dashboard.md`'s manual review queue). The
/// host can still create draft events while waiting, just not publish.
///
/// Mirrors the H-04 frame in the design project's
/// `After Hours - Host screens.dc.html` — status card, banner, document
/// list, and bottom action — token for token.
class HostVerificationPage extends ConsumerWidget {
  const HostVerificationPage({super.key});

  ({String label, AhTone tone}) _badgeFor(
    HostDocumentVerificationStatus status,
  ) {
    return switch (status) {
      HostDocumentVerificationStatus.verified => (
        label: 'Verified',
        tone: AhTone.success,
      ),
      HostDocumentVerificationStatus.rejected => (
        label: 'Rejected',
        tone: AhTone.error,
      ),
      HostDocumentVerificationStatus.pending => (
        label: 'In review',
        tone: AhTone.accent,
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final statusAsync = ref.watch(hostVerificationStatusControllerProvider);
    final controller = ref.read(
      hostVerificationStatusControllerProvider.notifier,
    );

    return PopScope(
      // The wizard is done once documents are submitted for review —
      // system back/gesture must not return to H-03 · Documents to
      // resubmit, same as the app bar already hiding its back button.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text('Verification', style: typography.h3),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: statusAsync.when(
              data: (documents) => _VerificationContent(
                documents: documents,
                badgeFor: _badgeFor,
              ),
              loading: () => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.xl,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                children: const [Center(child: CircularProgressIndicator())],
              ),
              error: (error, _) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.lg,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                children: const [
                  AhAlertBanner(
                    message:
                        "Couldn't load your verification status. Pull down "
                        'to try again.',
                    tone: AhBannerTone.error,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationContent extends StatelessWidget {
  const _VerificationContent({required this.documents, required this.badgeFor});

  final List<HostDocumentStatus> documents;
  final ({String label, AhTone tone}) Function(HostDocumentVerificationStatus)
  badgeFor;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final allVerified = documents.allVerified;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.lg,
            ),
            children: [
              AhCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      allVerified ? Icons.verified_user : Icons.hourglass_top,
                      size: 28,
                      color: allVerified
                          ? AppColors.trustVerified
                          : AppColors.actionPrimary,
                    ),
                    AppSpacing.spacerSm,
                    Text(
                      allVerified ? 'Verified' : 'Under review',
                      style: typography.h2,
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.spacerXs,
                    Text(
                      allVerified
                          ? 'Every document checked out. You can publish '
                                'events and take bookings.'
                          : "We review every host's first documents by "
                                'hand. Usually within 1 business day.',
                      style: typography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              AppSpacing.spacerMd,
              AhAlertBanner(
                message: allVerified
                    ? 'You can publish events now. Your first three go '
                          'through admin approval.'
                    : 'Publishing needs verification first. Try refershing the page or recheck after some time',
                tone: allVerified ? AhBannerTone.success : AhBannerTone.info,
              ),
              AppSpacing.spacerMd,
              Text(
                'DOCUMENTS',
                style: typography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              AppSpacing.spacerSm,
              for (final doc in documents) ...[
                _DocumentStatusRow(
                  label: doc.docType?.label ?? 'Document',
                  reason: doc.reason,
                  badge: badgeFor(doc.status),
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
            child: allVerified
                ? AhButton(
                    label: 'Go to home',
                    fullWidth: true,
                    onPressed: () => context.go('/host/home'),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      AppSpacing.spacerSm,
                      Flexible(
                        child: Text(
                          'Home unlocks once every document is verified',
                          style: typography.bodySm.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _DocumentStatusRow extends StatelessWidget {
  const _DocumentStatusRow({
    required this.label,
    required this.badge,
    this.reason,
  });

  final String label;
  final ({String label, AhTone tone}) badge;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return AhCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: typography.body)),
              AhBadge(label: badge.label, tone: badge.tone),
            ],
          ),
          if (reason != null && reason!.isNotEmpty) ...[
            AppSpacing.spacerXs,
            Text(
              reason!,
              style: typography.caption.copyWith(color: AppColors.statusError),
            ),
          ],
        ],
      ),
    );
  }
}
