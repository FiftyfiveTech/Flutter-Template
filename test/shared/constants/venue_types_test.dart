import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/shared/constants/venue_types.dart';

/// Backend `VenueCategory` values, per `CreateVenueDto.allowedVenueTypes`.
const _backendVenueTypes = [
  'restaurant', 'cafe', 'rooftop cafe', 'rooftop bar', 'bar', 'pub', //
  'lounge', 'brewery', 'wine bar', 'speakeasy', 'bistro', 'dessert parlour',
  'art studio', 'pottery studio', 'cooking studio', 'board game cafe',
  'gaming arcade', 'bowling alley', 'dance studio', 'live music venue',
  'comedy club', 'bookstore cafe', 'gallery', 'garden', 'terrace',
  'poolside', 'banquet hall', 'coworking space', 'other',
];

void main() {
  test('every label maps to exactly the backend VenueCategory enum', () {
    expect(kVenueTypeOptions.map(venueTypeToApi).toList(), _backendVenueTypes);
  });

  test('every backend value maps back to its label', () {
    expect(
      _backendVenueTypes.map(venueTypeFromApi).toList(),
      kVenueTypeOptions,
    );
  });
}
