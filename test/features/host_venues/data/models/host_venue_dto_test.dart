import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_venues/data/models/host_venue_dto.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue_photo.dart';

void main() {
  group('HostVenueDto.fromJson', () {
    test('defaults photos to an empty list when the field is absent', () {
      final dto = HostVenueDto.fromJson({
        'id': 'venue-1',
        'name': 'Toit, Indiranagar',
        'addLine1': '12, 100 Feet Road',
        'locality': 'Indiranagar',
        'city': 'city-1',
        'pincode': '560038',
        'maxCapacity': 40,
        'allowedVenueTypes': ['restaurant'],
      });

      expect(dto.toDomain().photos, isEmpty);
    });

    test('parses a photos array of {id, url} into HostVenuePhoto entities', () {
      final dto = HostVenueDto.fromJson({
        'id': 'venue-1',
        'name': 'Toit, Indiranagar',
        'addLine1': '12, 100 Feet Road',
        'locality': 'Indiranagar',
        'city': 'city-1',
        'pincode': '560038',
        'maxCapacity': 40,
        'allowedVenueTypes': ['restaurant'],
        'photos': [
          {'id': 'p1', 'url': 'https://example.com/p1.jpg'},
          {'id': 'p2', 'url': 'https://example.com/p2.jpg'},
        ],
      });

      final photos = dto.toDomain().photos;
      expect(photos, hasLength(2));
      expect(photos[0].id, 'p1');
      expect(photos[0].url, 'https://example.com/p1.jpg');
      expect(photos[1].id, 'p2');
    });

    test('reads a bare city id string with no display name', () {
      final dto = HostVenueDto.fromJson({
        'id': 'venue-1',
        'name': 'Toit, Indiranagar',
        'addLine1': '12, 100 Feet Road',
        'locality': 'Indiranagar',
        'city': '507f1f77bcf86cd799439011',
        'pincode': '560038',
        'maxCapacity': 40,
        'allowedVenueTypes': ['restaurant'],
      });

      final venue = dto.toDomain();
      expect(venue.cityId, '507f1f77bcf86cd799439011');
      expect(venue.cityName, isEmpty);
    });

    test('reads an expanded {id, name} city object when the backend '
        'provides one', () {
      final dto = HostVenueDto.fromJson({
        'id': 'venue-1',
        'name': 'Toit, Indiranagar',
        'addLine1': '12, 100 Feet Road',
        'locality': 'Indiranagar',
        'city': {'id': '507f1f77bcf86cd799439011', 'name': 'Bangalore'},
        'pincode': '560038',
        'maxCapacity': 40,
        'allowedVenueTypes': ['restaurant'],
      });

      final venue = dto.toDomain();
      expect(venue.cityId, '507f1f77bcf86cd799439011');
      expect(venue.cityName, 'Bangalore');
    });

    test('maps backend venue-type values to display labels', () {
      final dto = HostVenueDto.fromJson({
        'id': 'venue-1',
        'name': 'Toit, Indiranagar',
        'addLine1': '12, 100 Feet Road',
        'locality': 'Indiranagar',
        'city': 'city-1',
        'pincode': '560038',
        'maxCapacity': 40,
        'allowedVenueTypes': ['rooftop bar', 'live music venue', 'pub'],
      });

      expect(dto.toDomain().allowedVenueTypes, [
        'Rooftop bar',
        'Live music venue',
        'Pub',
      ]);
    });
  });

  group('HostVenueDto.toJson', () {
    const venue = HostVenue(
      id: 'venue-1',
      name: 'Toit, Indiranagar',
      addLine1: '12, 100 Feet Road',
      addLine2: '',
      locality: 'Indiranagar',
      cityId: '507f1f77bcf86cd799439011',
      cityName: 'Bangalore',
      pincode: '560038',
      maxCapacity: 40,
      allowedVenueTypes: ['Restaurant'],
      photos: [
        HostVenuePhoto(id: 'p1', url: 'https://example.com/p1.jpg'),
        HostVenuePhoto(id: 'p2', url: 'https://example.com/p2.jpg'),
      ],
    );

    test('sends allowedVenueTypes as backend enum values, not labels', () {
      final json = HostVenueDto.fromDomain(
        venue.copyWith(allowedVenueTypes: ['Rooftop bar', 'Pub']),
      ).toJson();

      expect(json['allowedVenueTypes'], ['rooftop bar', 'pub']);
      expect(json.containsKey('allowedEventTypes'), isFalse);
    });

    test('serializes photos as a plain list of ids, not the full object', () {
      final json = HostVenueDto.fromDomain(venue).toJson();

      expect(json['photos'], ['p1', 'p2']);
      expect(json.containsKey('id'), isFalse);
    });

    test('sends an empty photos list when the venue has no photos', () {
      final json = HostVenueDto.fromDomain(venue.copyWith(photos: [])).toJson();

      expect(json['photos'], isEmpty);
    });

    test('sends city as the bare id, never the display name', () {
      final json = HostVenueDto.fromDomain(venue).toJson();

      expect(json['city'], '507f1f77bcf86cd799439011');
    });

    test('omits addLine2 entirely when blank', () {
      final json = HostVenueDto.fromDomain(
        venue.copyWith(addLine2: ''),
      ).toJson();

      expect(json.containsKey('addLine2'), isFalse);
    });

    test('includes addLine2 when present', () {
      final json = HostVenueDto.fromDomain(
        venue.copyWith(addLine2: 'Near the metro station'),
      ).toJson();

      expect(json['addLine2'], 'Near the metro station');
    });
  });
}
