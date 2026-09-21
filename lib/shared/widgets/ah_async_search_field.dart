import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A labeled, debounced, remotely-searched single-choice field — type to
/// query [search], pick one of the returned options. Use this instead of
/// [AhSearchField] once the option list can't be enumerated up front and
/// has to be looked up from an API (cities, venues, anything backend-owned).
class AhAsyncSearchField<T extends Object> extends StatefulWidget {
  const AhAsyncSearchField({
    super.key,
    required this.label,
    required this.value,
    required this.search,
    required this.displayStringForOption,
    required this.onSelected,
    this.placeholder,
    this.errorText,
    this.debounce = const Duration(milliseconds: 300),
  });

  final String label;
  final String value;
  final Future<List<T>> Function(String query) search;
  final String Function(T option) displayStringForOption;
  final ValueChanged<T> onSelected;
  final String? placeholder;
  final String? errorText;
  final Duration debounce;

  @override
  State<AhAsyncSearchField<T>> createState() => _AhAsyncSearchFieldState<T>();
}

class _AhAsyncSearchFieldState<T extends Object>
    extends State<AhAsyncSearchField<T>> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<List<T>> _debouncedSearch(String query) {
    _debounceTimer?.cancel();
    final completer = Completer<List<T>>();
    _debounceTimer = Timer(widget.debounce, () {
      widget
          .search(query)
          .then(completer.complete, onError: completer.completeError);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: typography.bodySm),
        AppSpacing.spacerXs,
        Autocomplete<T>(
          initialValue: TextEditingValue(text: widget.value),
          displayStringForOption: widget.displayStringForOption,
          optionsBuilder: (textEditingValue) =>
              _debouncedSearch(textEditingValue.text),
          onSelected: widget.onSelected,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: typography.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: typography.body.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
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
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          widget.displayStringForOption(option),
                          style: typography.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (hasError) ...[
          AppSpacing.spacerXs,
          Text(
            widget.errorText!,
            style: typography.caption.copyWith(color: AppColors.statusError),
          ),
        ],
      ],
    );
  }
}
