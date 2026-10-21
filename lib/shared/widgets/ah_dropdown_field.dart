import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A labeled dropdown for a short, fixed list of choices. Use
/// [AhSearchField] instead once the option list is long enough that
/// scrolling to find one isn't practical.
class AhDropdownField extends StatelessWidget {
  const AhDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.errorText,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  /// Shown when [value] isn't (yet) one of [options] — e.g. before the
  /// host has made an explicit choice. Leaving this unset and [value]
  /// empty falls back to the field's default unselected look.
  final String? hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.bodySm),
        AppSpacing.spacerXs,
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : null,
          isExpanded: true,
          hint: hint == null
              ? null
              : Text(
                  hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
          dropdownColor: context.colors.surfaceCard,
          style: typography.body.copyWith(color: context.colors.textPrimary),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: context.colors.textTertiary,
          ),
          decoration: InputDecoration(
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
        ],
      ],
    );
  }
}
