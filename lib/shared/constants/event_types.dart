import '../utils/option_filter.dart';

/// An event's `format` vocabulary (backend `EventFormat` enum), as display
/// labels — H-08's Format picker.
///
/// Each label lowercased must equal the backend value exactly — e.g.
/// "Wine tasting" -> `wine tasting` — since [eventTypeToApi] derives the
/// wire value from it.
const kEventTypeOptions = [
  'Dinner',
  'Brunch',
  'Tasting',
  'Wine tasting',
  'Whisky tasting',
  'Beer tasting',
  'Coffee tasting',
  'Cocktail making',
  'Cooking class',
  'Baking class',
  'Supper club',
  'Pottery',
  'Painting',
  'Sip and paint',
  'Candle making',
  'Terrarium making',
  'Photography walk',
  'Workshop',
  'Board games',
  'Trivia night',
  'Quiz night',
  'Murder mystery',
  'Escape room',
  'Bowling',
  'Karaoke',
  'Music',
  'Open mic',
  'Jam session',
  'Dance',
  'Salsa night',
  'Stand up',
  'Improv',
  'Poetry night',
  'Movie screening',
  'Party',
  'Mixer',
  'Speed dating',
  'Book club',
  'Debate night',
  'Yoga',
  'Run club',
  'Hike',
  'Cycling',
  'Picnic',
  'Stargazing',
  'Other',
];

/// The backend `format` value for a [kEventTypeOptions] label.
String eventTypeToApi(String label) => optionToApi(label);

/// The [kEventTypeOptions] label for a backend `format` value.
String eventTypeFromApi(String value) =>
    optionFromApi(kEventTypeOptions, value);
