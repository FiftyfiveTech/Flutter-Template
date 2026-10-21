import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A labeled, debounced, remotely-searched single-choice field — type to
/// query [search], pick one of the returned options. Use this instead of
/// [AhSearchField] once the option list can't be enumerated up front and
/// has to be looked up from an API (cities, venues, anything backend-owned).
/// [search] may equally filter a local list — anything long enough that a
/// plain dropdown is a chore to scan (e.g. event types).
///
/// For a multi-select, set [clearOnSelect] and render the picked values
/// yourself (e.g. as removable `AhChipSelect` chips): each pick is
/// reported via [onSelected] and the field resets for the next search.
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
    this.searchOnEmptyQuery = false,
    this.clearOnSelect = false,
  });

  final String label;
  final String value;
  final Future<List<T>> Function(String query) search;
  final String Function(T option) displayStringForOption;
  final ValueChanged<T> onSelected;
  final String? placeholder;
  final String? errorText;
  final Duration debounce;

  /// Whether [search] is called when the field is cleared (empty query).
  /// Defaults to false so clearing the field just closes the options list,
  /// matching every other field's behavior — opt in only when [search]
  /// is meant to return a default/full list for an empty query.
  final bool searchOnEmptyQuery;

  /// Empties the field and closes the keyboard after each pick, instead of
  /// showing the picked option — for multi-select use.
  final bool clearOnSelect;

  @override
  State<AhAsyncSearchField<T>> createState() => _AhAsyncSearchFieldState<T>();
}

class _AhAsyncSearchFieldState<T extends Object>
    extends State<AhAsyncSearchField<T>> {
  Timer? _debounceTimer;
  late final TextEditingController _controller = TextEditingController(
    text: widget.clearOnSelect ? '' : widget.value,
  );
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant AhAsyncSearchField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect a value set from outside (e.g. an edited record loading
    // after the form opened) — Autocomplete only reads it once otherwise.
    if (!widget.clearOnSelect &&
        widget.value != oldWidget.value &&
        _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSelected(T option) {
    widget.onSelected(option);
    if (!widget.clearOnSelect) return;
    _controller.clear();
    _focusNode.unfocus();
  }

  Future<List<T>> _debouncedSearch(String query) {
    if (query.isEmpty && !widget.searchOnEmptyQuery) {
      return Future.value(const []);
    }
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
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: widget.displayStringForOption,
          optionsBuilder: (textEditingValue) =>
              _debouncedSearch(textEditingValue.text),
          onSelected: _onSelected,
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
