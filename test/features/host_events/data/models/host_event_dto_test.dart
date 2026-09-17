import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_events/data/models/host_event_dto.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event_photo.dart';

void main() {
  group('HostEventDto.fromJson', () {
    test('parses a real create-event response', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Wine & Cheese Night',
        'description': 'An intimate evening.',
        'format': 'dinner',
        'startsAt': '2026-10-10T13:00:00.000Z',
        'endsAt': '2026-10-10T16:00:00.000Z',
        'doorsOpenAt': '2026-10-10T12:30:00.000Z',
        'venueId': 'venue-1',
        'venueName': 'Toit, Indiranagar',
        'venueExactAddress': '100 Ft Road, Indiranagar, 560038',
        'neighbourhood': 'Indiranagar',
        'capacity': 60,
        'ratioConfig': {
          'targetPercent': 50,
          'toleranceBandPoints': 10,
          'releaseSchedule': {'minFemaleSeatsBeforeMaleRelease': 0},
        },
        'ticketTypes': [
          {
            'id': 'tt-1',
            'name': 'Early bird',
            'pricePaise': 150000,
            'quantity': 20,
            'active': true,
          },
        ],
        'cancellationTerms': 'Full refund up to 48 hours before the event.',
        'refundCutoffHoursBeforeStart': 48,
        'status': 'draft',
      });

      final event = dto.toDomain();
      expect(event.title, 'Wine & Cheese Night');
      expect(
        event.format,
        'Dinner',
        reason:
            'the raw slug "dinner" from the API must map back to the '
            'display-cased label the Format dropdown\'s options use, or '
            'it will never show as selected',
      );
      expect(event.venueId, 'venue-1');
      expect(event.venueName, 'Toit, Indiranagar');
      expect(event.venueAddress, '100 Ft Road, Indiranagar, 560038');
      expect(event.neighbourhood, 'Indiranagar');
      expect(event.capacity, 60);
      expect(event.ticketPriceRupees, 1500);
      expect(event.ratioTightened, isFalse);
      expect(event.holdbackEnabled, isFalse);
      expect(event.refundCutoffHoursBeforeStart, 48);
      expect(event.status, HostEventLifecycleStatus.draft);
      expect(
        event.startAt,
        DateTime.parse('2026-10-10T13:00:00.000Z').toLocal(),
      );
    });

    test('maps a multi-word format slug back to its display label', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Test',
        'venueId': 'venue-1',
        'capacity': 40,
        'format': 'board_games',
      });

      expect(dto.toDomain().format, 'Board games');
    });

    test('keeps an unrecognized format slug as-is rather than blanking it', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Test',
        'venueId': 'venue-1',
        'capacity': 40,
        'format': 'karaoke_night',
      });

      expect(dto.toDomain().format, 'karaoke_night');
    });

    test('falls back to unknown for an unrecognized status', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Test',
        'venueId': 'venue-1',
        'capacity': 40,
        'status': 'something_new',
      });

      expect(dto.toDomain().status, HostEventLifecycleStatus.unknown);
    });

    test(
      'a tightened tolerance band (5 points) maps to ratioTightened true',
      () {
        final dto = HostEventDto.fromJson({
          'id': 'event-1',
          'title': 'Test',
          'venueId': 'venue-1',
          'capacity': 40,
          'ratioConfig': {
            'targetPercent': 50,
            'toleranceBandPoints': 5,
            'releaseSchedule': {'minFemaleSeatsBeforeMaleRelease': 0},
          },
        });

        expect(dto.toDomain().ratioTightened, isTrue);
      },
    );

    test('a positive minFemaleSeatsBeforeMaleRelease maps to holdbackEnabled '
        'true', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Test',
        'venueId': 'venue-1',
        'capacity': 40,
        'ratioConfig': {
          'targetPercent': 50,
          'toleranceBandPoints': 10,
          'releaseSchedule': {'minFemaleSeatsBeforeMaleRelease': 8},
        },
      });

      expect(dto.toDomain().holdbackEnabled, isTrue);
    });

    test('defaults photos to an empty list when the field is absent', () {
      final dto = HostEventDto.fromJson({
        'id': 'event-1',
        'title': 'Test',
        'venueId': 'venue-1',
        'capacity': 40,
      });

      expect(dto.toDomain().photos, isEmpty);
    });
  });

  group('HostEventDto.toJson', () {
    final event = HostEvent(
      id: '',
      title: 'Wine & Cheese Night',
      description: 'An intimate evening.',
      format: 'Board games',
      startAt: DateTime(2026, 10, 10, 18, 30),
      endAt: DateTime(2026, 10, 10, 21, 30),
      doorsOpenAt: DateTime(2026, 10, 10, 18),
      venueId: 'venue-1',
      venueName: 'Toit, Indiranagar',
      venueAddress: 'ignored on write',
      neighbourhood: 'Indiranagar',
      capacity: 60,
      ticketPriceRupees: 1500,
      ratioTightened: false,
      holdbackEnabled: false,
      cancellationTerms: 'Full refund up to 48 hours before the event.',
      refundCutoffHoursBeforeStart: 48,
      coverPhoto: const HostEventPhoto(
        id: 'cover-1',
        url: 'https://example.com/cover.jpg',
      ),
      photos: const [
        HostEventPhoto(id: 'p1', url: 'https://example.com/p1.jpg'),
      ],
      status: HostEventLifecycleStatus.draft,
    );

    test('formats dates as yyyy-MM-dd HH:mm with no timezone offset', () {
      final json = HostEventDto.fromDomain(event).toJson();

      expect(json['startsAt'], '2026-10-10 18:30');
      expect(json['endsAt'], '2026-10-10 21:30');
      expect(json['doorsOpenAt'], '2026-10-10 18:00');
    });

    test('sends venueId as a bare id and omits venueAddress', () {
      final json = HostEventDto.fromDomain(event).toJson();

      expect(json['venueId'], 'venue-1');
      expect(json.containsKey('venueAddress'), isFalse);
    });

    test('slugifies format to the backend vocabulary', () {
      final json = HostEventDto.fromDomain(event).toJson();

      expect(json['format'], 'board_games');
    });

    test('sends ratioConfig with a 50 target and a 10-point default band', () {
      final json = HostEventDto.fromDomain(event).toJson();
      final ratioConfig = json['ratioConfig'] as Map<String, dynamic>;

      expect(ratioConfig['targetPercent'], 50);
      expect(ratioConfig['toleranceBandPoints'], 10);
      final releaseSchedule =
          ratioConfig['releaseSchedule'] as Map<String, dynamic>;
      expect(releaseSchedule['minFemaleSeatsBeforeMaleRelease'], 0);
    });

    test('a tightened ratio band narrows toleranceBandPoints to 5', () {
      final json = HostEventDto.fromDomain(
        event.copyWith(ratioTightened: true),
      ).toJson();
      final ratioConfig = json['ratioConfig'] as Map<String, dynamic>;

      expect(ratioConfig['toleranceBandPoints'], 5);
    });

    test('enabling holdback sets minFemaleSeatsBeforeMaleRelease to the '
        'threshold', () {
      final json = HostEventDto.fromDomain(
        event.copyWith(holdbackEnabled: true),
      ).toJson();
      final ratioConfig = json['ratioConfig'] as Map<String, dynamic>;
      final releaseSchedule =
          ratioConfig['releaseSchedule'] as Map<String, dynamic>;

      expect(
        releaseSchedule['minFemaleSeatsBeforeMaleRelease'],
        kHoldbackFemaleSeatsThreshold,
      );
    });

    test('sends a single General admission ticket type covering the full '
        'capacity', () {
      final json = HostEventDto.fromDomain(event).toJson();
      final ticketTypes = json['ticketTypes'] as List<dynamic>;

      expect(ticketTypes, hasLength(1));
      final ticketType = ticketTypes.first as Map<String, dynamic>;
      expect(ticketType['name'], 'General admission');
      expect(ticketType['pricePaise'], 150000);
      expect(ticketType['quantity'], 60);
      expect(ticketType['active'], isTrue);
    });

    test('sends coverPhotoId as a bare id when a cover photo is set', () {
      final json = HostEventDto.fromDomain(event).toJson();

      expect(json['coverPhotoId'], 'cover-1');
    });

    test('omits coverPhotoId when no cover photo is set', () {
      // copyWith can't null out coverPhoto (matches the domain's "no
      // clear, only replace" semantics) — build a fresh event with no
      // cover to exercise the omitted-key path instead.
      final noCoverEvent = HostEvent(
        id: event.id,
        title: event.title,
        description: event.description,
        format: event.format,
        startAt: event.startAt,
        endAt: event.endAt,
        doorsOpenAt: event.doorsOpenAt,
        venueId: event.venueId,
        venueName: event.venueName,
        venueAddress: event.venueAddress,
        neighbourhood: event.neighbourhood,
        capacity: event.capacity,
        ticketPriceRupees: event.ticketPriceRupees,
        ratioTightened: event.ratioTightened,
        holdbackEnabled: event.holdbackEnabled,
        cancellationTerms: event.cancellationTerms,
        refundCutoffHoursBeforeStart: event.refundCutoffHoursBeforeStart,
        coverPhoto: null,
        photos: const [],
        status: event.status,
      );
      final json = HostEventDto.fromDomain(noCoverEvent).toJson();

      expect(json.containsKey('coverPhotoId'), isFalse);
    });

    test('sends the gallery photos array as ids only', () {
      final json = HostEventDto.fromDomain(event).toJson();

      expect(json['photos'], ['p1']);
    });
  });
}
