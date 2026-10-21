import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/di/theme_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_avatar.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../../../shared/widgets/ah_confirm_dialog.dart';
import '../../../../shared/widgets/ah_segmented_control.dart';
import '../../../../shared/widgets/ah_verification_badge.dart';
import '../../../host_home/presentation/widgets/host_home_bottom_nav.dart';
import '../controllers/host_you_controller.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';

/// H-12 · Profile — account summary (tap to edit), appearance, venues
/// shortcut and session actions. The Account section (payout account) is hidden until payouts
/// exist. Appearance switches the app between Light (default), Dark and
/// System and is remembered across restarts.
class HostYouPage extends ConsumerWidget {
  const HostYouPage({super.key});

  /// Segment order of the Appearance control.
  static const _appearanceModes = [
    ThemeMode.light,
    ThemeMode.dark,
    ThemeMode.system,
  ];

  /// Reloads on return so the card reflects the saved name/photo.
  Future<void> _openEditProfile(BuildContext context, WidgetRef ref) async {
    await context.push('/host/you/edit');
    if (!context.mounted) return;
    ref.read(hostYouControllerProvider.notifier).load();
  }

  /// Opens H-04 and reloads on return so the badge reflects any review
  /// that completed meanwhile.
  Future<void> _openVerification(BuildContext context, WidgetRef ref) async {
    await context.push('/host/verification');
    if (!context.mounted) return;
    ref.read(hostYouControllerProvider.notifier).load();
  }

  /// Reloads on return so the saved-venues count reflects venues added or
  /// removed meanwhile.
  Future<void> _openVenues(BuildContext context, WidgetRef ref) async {
    await context.push('/host/venues');
    if (!context.mounted) return;
    ref.read(hostYouControllerProvider.notifier).load();
  }

  void _logOut(BuildContext context, WidgetRef ref) {
    ref.read(hostYouControllerProvider.notifier).clearCache();
    ref.read(hostSessionControllerProvider.notifier).clear();
    context.go('/');
  }

  /// Warns first; only a confirmed delete calls `DELETE /api/v1/host/me`.
  /// The session ends only once the server has deleted the account — a
  /// failure keeps the host signed in and shows the error.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showAhConfirmDialog(
      context,
      title: 'Delete this account?',
      message:
          'Removes your listings and payout details. Settle events with '
          "sold seats first. This can't be undone.",
      confirmLabel: 'Delete account',
      cancelLabel: 'Keep my account',
    );
    if (!confirmed || !context.mounted) return;
    final deleted = await ref
        .read(hostYouControllerProvider.notifier)
        .deleteAccount();
    if (!deleted || !context.mounted) return;
    ref.read(hostSessionControllerProvider.notifier).clear();
    context.go('/');
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
      backgroundColor: context.colors.backgroundPrimary,
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
                  'Profile',
                  style: typography.h1.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: state.isLoading && state.hostName == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colors.actionPrimary,
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
                          onTap: () => _openEditProfile(context, ref),
                          child: Row(
                            children: [
                              _EditableAvatar(
                                name: state.hostName ?? '',
                                photoPath: state.photoPath,
                              ),
                              const SizedBox(width: AppSpacing.sm + 2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.hostName ?? '',
                                      style: typography.h3.copyWith(
                                        color: context.colors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Venue host',
                                      style: typography.bodySm.copyWith(
                                        color: context.colors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AhVerificationBadge(
                                isVerified: state.isVerified,
                                onTap: () => _openVerification(context, ref),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('APPEARANCE', typography: typography),
                        const SizedBox(height: AppSpacing.sm),
                        AhSegmentedControl(
                          labels: const ['Light', 'Dark', 'System'],
                          selectedIndex: _appearanceModes.indexOf(
                            ref.watch(themeModeControllerProvider),
                          ),
                          onChanged: (index) => ref
                              .read(themeModeControllerProvider.notifier)
                              .setMode(_appearanceModes[index]),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AhCard(
                          onTap: () => _openVenues(context, ref),
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
                          child: _AccountRow(
                            icon: Icons.logout,
                            label: 'Log out',
                            color: context.colors.statusError,
                            showChevron: false,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.cardGap),
                        _DeleteAccountRow(
                          isDeleting: state.isDeletingAccount,
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

/// The profile card's avatar with an edit hint — the whole card is the tap
/// target that opens Edit profile.
class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.name, required this.photoPath});

  final String name;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Edit profile',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AhAvatar(name: name, photoPath: photoPath),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs / 2),
              decoration: BoxDecoration(
                color: context.colors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.borderDefault),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 12,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
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
        color: context.colors.textTertiary,
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
    final rowColor = color ?? context.colors.textPrimary;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (color ?? context.colors.textTertiary).withValues(
              alpha: 0.14,
            ),
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
            style: typography.bodySm.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (showChevron)
          Icon(
            Icons.chevron_right,
            size: 18,
            color: context.colors.textTertiary,
          ),
      ],
    );
  }
}

class _DeleteAccountRow extends StatelessWidget {
  const _DeleteAccountRow({required this.isDeleting, required this.onTap});

  final bool isDeleting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: context.colors.statusError),
          ),
          child: Row(
            children: [
              if (isDeleting)
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.statusError,
                  ),
                )
              else
                Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: context.colors.statusError,
                ),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                isDeleting ? 'Deleting account…' : 'Delete account',
                style: typography.body.copyWith(
                  color: context.colors.statusError,
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
