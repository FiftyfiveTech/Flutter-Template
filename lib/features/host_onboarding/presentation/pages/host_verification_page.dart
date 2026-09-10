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
class HostVerificationPage extends ConsumerWidget {
  const HostVerificationPage({super.key});

  String _label(HostDocumentStatus doc) => doc.docType?.label ?? 'Document';

  ({String label, AhTone tone}) _badge(HostDocumentVerificationStatus status) {
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
        label: 'Pending',
        tone: AhTone.warning,
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

    return Scaffold(
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
              badgeFor: _badge,
              labelFor: _label,
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
    );
  }
}

class _VerificationContent extends StatelessWidget {
  const _VerificationContent({
    required this.documents,
    required this.badgeFor,
    required this.labelFor,
  });

  final List<HostDocumentStatus> documents;
  final ({String label, AhTone tone}) Function(HostDocumentVerificationStatus)
  badgeFor;
  final String Function(HostDocumentStatus) labelFor;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final allVerified = documents.allVerified;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color:
                  (allVerified
                          ? AppColors.statusSuccess
                          : AppColors.statusWarning)
                      .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allVerified ? Icons.check_circle : Icons.hourglass_top,
              size: 32,
              color: allVerified
                  ? AppColors.statusSuccess
                  : AppColors.statusWarning,
            ),
          ),
        ),
        AppSpacing.spacerLg,
        Text(
          allVerified ? "You're verified!" : "You're under review",
          style: typography.h2,
          textAlign: TextAlign.center,
        ),
        AppSpacing.spacerSm,
        Text(
          allVerified
              ? 'Every document checks out. You can publish events now.'
              : "We've received your documents and payout details. Our "
                    'team checks every host manually — it usually takes '
                    '1-2 business days.',
          style: typography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        AppSpacing.spacerLg,
        if (!allVerified) ...[
          const AhAlertBanner(
            message:
                "You can start building a draft event now — you just "
                "won't be able to publish it until you're verified.",
            tone: AhBannerTone.info,
          ),
          AppSpacing.spacerLg,
        ],
        for (final doc in documents) ...[
          _DocumentStatusRow(
            label: labelFor(doc),
            reason: doc.reason,
            badge: badgeFor(doc.status),
          ),
          AppSpacing.spacerSm,
        ],
        AppSpacing.spacerMd,
        if (allVerified)
          AhButton(
            label: 'Go to host home',
            fullWidth: true,
            onPressed: () => context.go('/host/home'),
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
