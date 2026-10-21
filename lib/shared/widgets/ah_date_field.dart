import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

const _monthNames = [
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

/// A labeled date picker matching the design system's `DateTimeField`
/// component (date mode). Opens the platform date picker — no extra
/// dependency needed beyond `material.dart`.
class AhDateField extends StatelessWidget {
  const AhDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    // Drop focus first: the dialog hands focus back to whatever had it on
    // close, which would reopen a search field's list or the keyboard.
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 1),
      lastDate: lastDate ?? DateTime(now.year + 10),
    );
    if (picked != null) onChanged(picked);
  }

  String _format(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.bodySm),
        AppSpacing.spacerXs,
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: context.colors.surfaceCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: hasError
                    ? context.colors.statusError
                    : context.colors.borderDefault,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: context.colors.textTertiary,
                ),
                AppSpacing.spacerSm,
                Expanded(
                  child: Text(
                    value != null ? _format(value!) : 'Select date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: typography.body.copyWith(
                      color: value != null
                          ? context.colors.textPrimary
                          : context.colors.textTertiary,
                    ),
                  ),
                ),
              ],
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
