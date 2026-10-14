import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/document_picker_providers.dart';
import '../../../../core/di/session_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_avatar.dart';
import '../../../../shared/widgets/ah_badge.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../../../shared/widgets/ah_segmented_control.dart';
import '../../../host_home/presentation/widgets/host_home_bottom_nav.dart';
import '../controllers/host_you_controller.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';

/// H-12 · You — account summary, appearance, venues shortcut and session
/// actions. Appearance is shown read-only (locked to System) since the app
/// currently ships a single light theme only — no ThemeMode infra exists yet.
class HostYouPage extends ConsumerWidget {
  const HostYouPage({super.key});

  static const _photoExtensions = ['jpg', 'jpeg', 'png', 'heic', 'webp'];

  Future<void> _pickPhoto(WidgetRef ref) async {
    final picked = await ref
        .read(documentPickerProvider)
        .pickFile(allowedExtensions: _photoExtensions);
    if (picked == null) return;
    await ref.read(hostYouControllerProvider.notifier).setPhoto(picked.path);
  }

  void _logOut(BuildContext context, WidgetRef ref) {
    ref.read(hostYouControllerProvider.notifier).clearCache();
    ref.read(hostSessionControllerProvider.notifier).clear();
    context.go('/');
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (sheetContext) {
        final typography = Theme.of(sheetContext).extension<AppTypography>()!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete this account?', style: typography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Removes your listings and payout details. Settle events '
                "with sold seats first. This can't be undone.",
                style: typography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AhButton(
                label: 'Delete account',
                variant: AhButtonVariant.destructive,
                fullWidth: true,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _logOut(context, ref);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AhButton(
                label: 'Keep my account',
                variant: AhButtonVariant.tertiary,
                fullWidth: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(hostYouControllerProvider);
    ref.listen(hostYouControllerProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message == null) return;
      showAhMessageSheet(context, message: message, tone: AhMessageTone.error);
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'You',
                  style: typography.h1.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
            Expanded(
              child: state.isLoading && state.hostName == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.actionPrimary,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        0,
                        AppSpacing.gutter,
                        AppSpacing.xl,
                      ),
                      children: [
                        AhCard(
                          child: Row(
                            children: [
                              _EditableAvatar(
                                name: state.hostName ?? '',
                                photoPath: state.photoPath,
                                isSaving: state.isSavingPhoto,
                                onTap: () => _pickPhoto(ref),
                              ),
                              const SizedBox(width: AppSpacing.sm + 2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.hostName ?? '',
                                      style: typography.h3.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Venue host',
                                      style: typography.bodySm.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AhBadge(
                          label: state.isVerified
                              ? 'ID verified'
                              : 'Pending verification',
                          tone: state.isVerified
                              ? AhTone.trust
                              : AhTone.warning,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('APPEARANCE', typography: typography),
                        const SizedBox(height: AppSpacing.sm),
                        const AhSegmentedControl(
                          labels: ['Light', 'Dark', 'System'],
                          selectedIndex: 2,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('ACCOUNT', typography: typography),
                        const SizedBox(height: AppSpacing.sm),
                        AhCard(
                          onTap: () => showAhMessageSheet(
                            context,
                            message: 'Payout settings — coming soon',
                          ),
                          child: const _AccountRow(
                            icon: Icons.account_balance_outlined,
                            label: 'Payout account · HDFC ••4412',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.cardGap),
                        AhCard(
                          onTap: () => context.push('/host/venues'),
                          child: _AccountRow(
                            icon: Icons.storefront_outlined,
                            label: 'Venues',
                            trailingText: state.hostName == null
                                ? null
                                : '${state.savedVenuesCount} saved',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AhCard(
                          onTap: () => _logOut(context, ref),
                          child: const _AccountRow(
                            icon: Icons.logout,
                            label: 'Log out',
                            color: AppColors.statusError,
                            showChevron: false,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.cardGap),
                        _DeleteAccountRow(
                          onTap: () => _confirmDeleteAccount(context, ref),
                        ),
                      ],
                    ),
            ),
            HostHomeBottomNav(
              currentIndex: 2,
              onTap: (index) {
                if (index == 0) {
                  context.go('/host/home');
                } else if (index == 1) {
                  showAhMessageSheet(context, message: 'Payouts — coming soon');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.name,
    required this.photoPath,
    required this.isSaving,
    required this.onTap,
  });

  final String name;
  final String? photoPath;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: isSaving ? null : onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AhAvatar(name: name, photoPath: photoPath),
            if (isSaving)
              const Positioned.fill(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.actionPrimaryFg,
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs / 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.typography});

  final String text;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: typography.label.copyWith(
        letterSpacing: 1.1,
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    this.trailingText,
    this.color,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final Color? color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final rowColor = color ?? AppColors.textPrimary;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (color ?? AppColors.textTertiary).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: rowColor),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Text(
            label,
            style: typography.body.copyWith(
              color: rowColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingText != null) ...[
          Text(
            trailingText!,
            style: typography.bodySm.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (showChevron)
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textTertiary,
          ),
      ],
    );
  }
}

class _DeleteAccountRow extends StatelessWidget {
  const _DeleteAccountRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.statusError),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.statusError,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                'Delete account',
                style: typography.body.copyWith(
                  color: AppColors.statusError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
