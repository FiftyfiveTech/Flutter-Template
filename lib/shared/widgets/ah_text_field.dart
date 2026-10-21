import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The app's standard labeled text input — label above, optional leading
/// icon, inline error text below. Used for every form field so field
/// styling doesn't get re-implemented per screen.
class AhTextField extends StatelessWidget {
  const AhTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.placeholder,
    this.icon,
    this.errorText,
    this.helperText,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final IconData? icon;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;

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
          keyboardType: keyboardType,
          style: typography.body.copyWith(color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: typography.body.copyWith(
              color: context.colors.textTertiary,
            ),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: context.colors.textTertiary),
            filled: true,
            fillColor: context.colors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: context.colors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(
                color: hasError
                    ? context.colors.statusError
                    : context.colors.borderDefault,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(
                color: hasError
                    ? context.colors.statusError
                    : context.colors.actionPrimary,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          AppSpacing.spacerXs,
          Text(
            errorText!,
            style: typography.caption.copyWith(
              color: context.colors.statusError,
            ),
          ),
        ] else if (helperText != null) ...[
          AppSpacing.spacerXs,
          Text(
            helperText!,
            style: typography.caption.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}
