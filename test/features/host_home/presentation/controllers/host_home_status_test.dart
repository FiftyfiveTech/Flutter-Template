import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event.dart';
import 'package:host_mobile_app/features/host_home/domain/entities/host_home_event.dart';
import 'package:host_mobile_app/features/host_home/presentation/controllers/host_home_controller.dart';

HostEvent _event(
  HostEventLifecycleStatus status, {
  DateTime? startAt,
  DateTime? endAt,
}) {
  return HostEvent(
    id: 'evt-1',
    title: 'Blind Wine & Bad Takes',
    description: 'Six wines, labels off.',
    format: 'Tasting',
    startAt: startAt,
    endAt: endAt,
    doorsOpenAt: null,
    venueId: 'venue-1',
    venueName: 'Toit',
    venueAddress: '',
    neighbourhood: '',
    capacity: 40,
    ticketPriceRupees: 1299,
    toleranceBandPoints: 10,
    holdbackEnabled: false,
    cancellationTerms: '',
    refundCutoffHoursBeforeStart: 24,
    coverPhoto: null,
    photos: const [],
    status: status,
  );
}

void main() {
  final start = DateTime(2026, 10, 14, 20);
  final end = DateTime(2026, 10, 14, 23);

  HostEventStatus published(DateTime now, {DateTime? endAt}) =>
      toHostHomeStatus(
        _event(
          HostEventLifecycleStatus.published,
          startAt: start,
          endAt: endAt,
        ),
        now,
      );

  group('non-published lifecycle states', () {
    final now = DateTime(2026, 10, 14, 21);

    test('draft and unknown map to draft', () {
      expect(
        toHostHomeStatus(_event(HostEventLifecycleStatus.draft), now),
        HostEventStatus.draft,
      );
      expect(
        toHostHomeStatus(_event(HostEventLifecycleStatus.unknown), now),
        HostEventStatus.draft,
      );
    });

    test('submitted maps to in review, not draft', () {
      expect(
        toHostHomeStatus(_event(HostEventLifecycleStatus.submitted), now),
        HostEventStatus.inReview,
      );
    });

    test('cancelled stays cancelled even mid-window', () {
      expect(
        toHostHomeStatus(
          _event(
            HostEventLifecycleStatus.cancelled,
            startAt: start,
            endAt: end,
          ),
          now,
        ),
        HostEventStatus.cancelled,
      );
    });

    test('completed maps to completed', () {
      expect(
        toHostHomeStatus(_event(HostEventLifecycleStatus.completed), now),
        HostEventStatus.completed,
      );
    });
  });

  group('published, split by time', () {
    test('before start is upcoming', () {
      expect(
        published(start.subtract(const Duration(minutes: 1)), endAt: end),
        HostEventStatus.upcoming,
      );
    });

    test('exactly at start is live', () {
      expect(published(start, endAt: end), HostEventStatus.live);
    });

    test('between start and end is live', () {
      expect(
        published(start.add(const Duration(hours: 1)), endAt: end),
        HostEventStatus.live,
      );
    });

    test('exactly at end is completed', () {
      expect(published(end, endAt: end), HostEventStatus.completed);
    });

    test('started with no end time is completed', () {
      expect(
        published(start.add(const Duration(minutes: 1))),
        HostEventStatus.completed,
      );
    });

    test('no start time is upcoming', () {
      expect(
        toHostHomeStatus(
          _event(HostEventLifecycleStatus.published),
          DateTime(2026, 10, 14),
        ),
        HostEventStatus.upcoming,
      );
    });
  });

  group('check-in window', () {
    bool canCheckIn(
      DateTime now, {
      HostEventLifecycleStatus status = HostEventLifecycleStatus.published,
    }) => canOpenCheckIn(_event(status, startAt: start, endAt: end), now);

    test('closed until 12h before start', () {
      expect(canCheckIn(start.subtract(const Duration(hours: 13))), isFalse);
      expect(canCheckIn(start.subtract(const Duration(hours: 11))), isTrue);
    });

    test('open while live', () {
      expect(canCheckIn(start.add(const Duration(hours: 1))), isTrue);
    });

    test('closes the moment the event ends', () {
      expect(canCheckIn(end.subtract(const Duration(minutes: 1))), isTrue);
      expect(canCheckIn(end), isFalse);
      expect(canCheckIn(end.add(const Duration(hours: 1))), isFalse);
    });

    test('never for drafts, in-review, cancelled or completed events', () {
      for (final status in [
        HostEventLifecycleStatus.draft,
        HostEventLifecycleStatus.submitted,
        HostEventLifecycleStatus.cancelled,
        HostEventLifecycleStatus.completed,
      ]) {
        expect(canCheckIn(start, status: status), isFalse, reason: '$status');
      }
    });
  });

  group('home ordering', () {
    HostHomeEvent homeEvent(String id, HostEventStatus status) => HostHomeEvent(
      id: id,
      title: id,
      formattedSchedule: '',
      status: status,
      soldCount: null,
      capacity: 40,
    );

    test('completed events sink below the rest, order otherwise kept', () {
      final sorted = sortForHome([
        homeEvent('done-1', HostEventStatus.completed),
        homeEvent('upcoming', HostEventStatus.upcoming),
        homeEvent('done-2', HostEventStatus.completed),
        homeEvent('live', HostEventStatus.live),
        homeEvent('draft', HostEventStatus.draft),
      ]);

      expect(sorted.map((e) => e.id), [
        'upcoming',
        'live',
        'draft',
        'done-1',
        'done-2',
      ]);
    });
  });
}
