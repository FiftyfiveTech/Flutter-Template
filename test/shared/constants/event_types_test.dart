import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/shared/constants/event_types.dart';

/// Backend `EventFormat` values, per `CreateEventDto.format` in swagger.
const _backendFormats = [
  'dinner', 'brunch', 'tasting', 'wine tasting', 'whisky tasting', //
  'beer tasting', 'coffee tasting', 'cocktail making', 'cooking class',
  'baking class', 'supper club', 'pottery', 'painting', 'sip and paint',
  'candle making', 'terrarium making', 'photography walk', 'workshop',
  'board games', 'trivia night', 'quiz night', 'murder mystery',
  'escape room', 'bowling', 'karaoke', 'music', 'open mic', 'jam session',
  'dance', 'salsa night', 'stand up', 'improv', 'poetry night',
  'movie screening', 'party', 'mixer', 'speed dating', 'book club',
  'debate night', 'yoga', 'run club', 'hike', 'cycling', 'picnic',
  'stargazing', 'other',
];

void main() {
  test('every label maps to exactly the backend format enum', () {
    expect(kEventTypeOptions.map(eventTypeToApi).toList(), _backendFormats);
  });

  test('every backend value maps back to its label', () {
    expect(_backendFormats.map(eventTypeFromApi).toList(), kEventTypeOptions);
  });
}
