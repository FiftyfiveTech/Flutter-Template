import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'ah_button.dart';

enum AhMessageTone { info, success, error }

/// App-wide replacement for snackbars: a modal sheet that slides up from
/// the bottom with a tone icon, the message and a single dismiss button.
///
/// To show a message right after popping the current page (e.g. "Venue
/// saved" then `context.pop()`), capture `Navigator.of(context).context`
/// before popping and pass that — the page's own context is unmounted
/// once it's popped, and showing first would make the pop close the sheet.
Future<void> showAhMessageSheet(
  BuildContext context, {
  required String message,
  AhMessageTone tone = AhMessageTone.info,
  String? title,
  String buttonLabel = 'OK',
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusSheet),
      ),
    ),
    builder: (_) => _AhMessageSheet(
      message: message,
      tone: tone,
      title: title,
      buttonLabel: buttonLabel,
    ),
  );
}

class _AhMessageSheet extends StatelessWidget {
  const _AhMessageSheet({
    required this.message,
    required this.tone,
    required this.title,
    required this.buttonLabel,
  });

  final String message;
  final AhMessageTone tone;
  final String? title;
  final String buttonLabel;

  (IconData, Color, String) get _toneStyle => switch (tone) {
    AhMessageTone.info => (
      Icons.info_outline,
      AppColors.statusInfo,
      'Heads up',
    ),
    AhMessageTone.success => (
      Icons.check_circle_outline,
      AppColors.statusSuccess,
      'Done',
    ),
    AhMessageTone.error => (
      Icons.error_outline,
      AppColors.statusError,
      'Something went wrong',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final (icon, color, defaultTitle) = _toneStyle;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: AppSpacing.lg + 4),
            ),
            AppSpacing.spacerMd,
            Text(
              title ?? defaultTitle,
              style: typography.h2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: typography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.spacerLg,
            AhButton(
              label: buttonLabel,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
