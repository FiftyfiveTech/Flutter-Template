/// The backend's fixed event-type vocabulary — shared by H-07 (a venue's
/// `allowedEventTypes`) and H-08 (an event's `format`) so both stay in
/// sync from one place instead of drifting apart in two features.
///
/// Each label must slugify (lowercase, whitespace -> `_`) to the backend
/// enum value exactly — e.g. "Board games" -> `board_games`, "Stand up"
/// -> `stand_up` — since `HostEventDto` derives the wire value from it.
const kEventTypeOptions = [
  'Dinner',
  'Tasting',
  'Pottery',
  'Board games',
  'Party',
  'Music',
  'Dance',
  'Stand up',
  'Other',
];

/// Case-insensitive substring filter over [options], for an event-type
/// search field. An empty [query] returns every option, minus [exclude].
List<String> filterEventTypes(
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
