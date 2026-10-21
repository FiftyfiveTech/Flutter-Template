import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'ah_button.dart';

/// App-wide warning dialog for destructive or irreversible actions (delete
/// account, delete draft, …). Resolves to `true` only when the user taps
/// [confirmLabel]; tapping [cancelLabel], outside the dialog or back all
/// resolve to `false`, so callers can simply `if (!confirmed) return;`.
Future<bool> showAhConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _AhConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
  return confirmed ?? false;
}

class _AhConfirmDialog extends StatelessWidget {
  const _AhConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final accent = isDestructive
        ? AppColors.statusError
        : AppColors.actionPrimary;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.warning_amber_rounded, size: 32, color: accent),
            AppSpacing.spacerSm,
            Text(
              title,
              textAlign: TextAlign.center,
              style: typography.h3.copyWith(color: AppColors.textPrimary),
            ),
            AppSpacing.spacerSm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: typography.bodySm.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.spacerLg,
            AhButton(
              label: confirmLabel,
              variant: isDestructive
                  ? AhButtonVariant.destructive
                  : AhButtonVariant.primary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            AppSpacing.spacerSm,
            AhButton(
              label: cancelLabel,
              variant: AhButtonVariant.tertiary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
