import 'package:flutter/widgets.dart';

/// Scrolls to the first field (in [fieldKeys] order) present in
/// [fieldErrors], if its context is currently mounted.
void scrollToFirstError(
  Map<String, GlobalKey> fieldKeys,
  Map<String, String> fieldErrors,
) {
  for (final field in fieldKeys.keys) {
    if (!fieldErrors.containsKey(field)) continue;
    final fieldContext = fieldKeys[field]!.currentContext;
    if (fieldContext == null) continue;
    Scrollable.ensureVisible(
      fieldContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
    return;
  }
}
