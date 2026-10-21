import '../utils/option_filter.dart';

/// A venue's `allowedVenueTypes` vocabulary (backend `VenueCategory`
/// enum), as display labels — H-07's venue type picker.
///
/// Each label lowercased must equal the backend value exactly — e.g.
/// "Rooftop cafe" -> `rooftop cafe` — since [venueTypeToApi] derives the
/// wire value from it.
const kVenueTypeOptions = [
  'Restaurant',
  'Cafe',
  'Rooftop cafe',
  'Rooftop bar',
  'Bar',
  'Pub',
  'Lounge',
  'Brewery',
  'Wine bar',
  'Speakeasy',
  'Bistro',
  'Dessert parlour',
  'Art studio',
  'Pottery studio',
  'Cooking studio',
  'Board game cafe',
  'Gaming arcade',
  'Bowling alley',
  'Dance studio',
  'Live music venue',
  'Comedy club',
  'Bookstore cafe',
  'Gallery',
  'Garden',
  'Terrace',
  'Poolside',
  'Banquet hall',
  'Coworking space',
  'Other',
];

/// The backend `allowedVenueTypes` value for a [kVenueTypeOptions] label.
String venueTypeToApi(String label) => optionToApi(label);

/// The [kVenueTypeOptions] label for a backend `allowedVenueTypes` value.
String venueTypeFromApi(String value) =>
    optionFromApi(kVenueTypeOptions, value);
