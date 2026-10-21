/// Case-insensitive substring filter over [options], for a searchable
/// picker (e.g. `AhAsyncSearchField` over a fixed list). An empty [query]
/// returns every option, minus [exclude] (e.g. values already picked).
List<String> filterOptions(
  List<String> options,
  String query, {
  List<String> exclude = const [],
}) {
  final q = query.trim().toLowerCase();
  return [
    for (final option in options)
      if (!exclude.contains(option) && option.toLowerCase().contains(q)) option,
  ];
}

/// The backend value for a display [label] from a fixed option list —
/// the label lowercased, e.g. "Wine tasting" -> `wine tasting`.
String optionToApi(String label) => label.trim().toLowerCase();

/// Reverses [optionToApi] against [options]: maps a backend value to its
/// display label so it shows as selected. Underscores are read as spaces
/// (older backend values used `board_games`), and a value matching no
/// option is returned as-is rather than silently blanked.
String optionFromApi(List<String> options, String value) {
  final normalized = value.trim().toLowerCase().replaceAll('_', ' ');
  for (final option in options) {
    if (option.toLowerCase() == normalized) return option;
  }
  return value;
}
