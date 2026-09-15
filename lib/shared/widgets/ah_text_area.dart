import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Multiline sibling of [AhTextField] — same label/error/helper API, a
/// taller input with top-aligned text. Used for free-form copy fields such
/// as an event's description or cancellation terms.
class AhTextArea extends StatelessWidget {
  const AhTextArea({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.placeholder,
    this.errorText,
    this.helperText,
    this.minLines = 3,
    this.maxLines = 5,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final String? errorText;
  final String? helperText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.bodySm),
        AppSpacing.spacerXs,
        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines: minLines,
          maxLines: maxLines,
          textAlignVertical: TextAlignVertical.top,
          style: typography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: typography.body.copyWith(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.statusError
                    : AppColors.borderDefault,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.statusError
                    : AppColors.actionPrimary,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          AppSpacing.spacerXs,
          Text(
            errorText!,
            style: typography.caption.copyWith(color: AppColors.statusError),
          ),
        ] else if (helperText != null) ...[
          AppSpacing.spacerXs,
          Text(
            helperText!,
            style: typography.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }
}
