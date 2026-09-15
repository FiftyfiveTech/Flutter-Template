import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_events/data/models/host_event_dto.dart';

void main() {
  group('HostEventDto.fromJson', () {
    test('defaults photos to an empty list when the field is absent', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Blind Wine & Bad Takes',
        'venue': 'venue-1',
        'capacity': 40,
        'ticketPriceRupees': 1299,
      });

      expect(dto.toDomain().photos, isEmpty);
    });

    test('parses a photos array of {id, url} into HostEventPhoto entities', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Blind Wine & Bad Takes',
        'venue': 'venue-1',
        'capacity': 40,
        'ticketPriceRupees': 1299,
        'photos': [
          {'id': 'p1', 'url': 'https://example.com/p1.jpg'},
          {'id': 'p2', 'url': 'https://example.com/p2.jpg'},
        ],
      });

      final photos = dto.toDomain().photos;
      expect(photos, hasLength(2));
      expect(photos[0].id, 'p1');
      expect(photos[1].id, 'p2');
    });

    test('reads a bare venue id string with no address', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Blind Wine & Bad Takes',
        'venue': 'venue-1',
        'capacity': 40,
        'ticketPriceRupees': 1299,
      });

      final event = dto.toDomain();
      expect(event.venueId, 'venue-1');
      expect(event.venueAddress, isEmpty);
    });

    test(
      'parses startAt/endAt ISO strings, defaulting to null when absent',
      () {
        final dto = HostEventDto.fromJson({
          'id': 'event-1',
          'title': 'Blind Wine & Bad Takes',
          'venue': 'venue-1',
          'capacity': 40,
          'ticketPriceRupees': 1299,
          'startAt': '2026-09-12T20:00:00.000Z',
        });

        final event = dto.toDomain();
        expect(event.startAt, DateTime.parse('2026-09-12T20:00:00.000Z'));
        expect(event.endAt, isNull);
      },
    );
  });

  group('HostEventDto.toJson', () {
    test('omits startAt/endAt when null and sends venue as a bare id', () {
      const dto = HostEventDto(
        id: '',
        title: 'Blind Wine & Bad Takes',
        description: 'desc',
        format: 'Tasting',
        startAt: null,
        endAt: null,
        venueId: 'venue-1',
        venueAddress: 'ignored on write',
        capacity: 40,
        ticketPriceRupees: 1299,
        ratioTightened: false,
        holdbackEnabled: false,
        cancellationTerms: 'No refunds within 24h of doors.',
        photos: [],
      );

      final json = dto.toJson();

      expect(json.containsKey('startAt'), isFalse);
      expect(json.containsKey('endAt'), isFalse);
      expect(json['venue'], 'venue-1');
      expect(json.containsKey('venueAddress'), isFalse);
    });
  });
}
