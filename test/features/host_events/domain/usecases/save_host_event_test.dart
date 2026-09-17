import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event_photo.dart';
import 'package:host_mobile_app/features/host_events/domain/repositories/host_events_repository.dart';
import 'package:host_mobile_app/features/host_events/domain/usecases/save_host_event.dart';

class _FakeHostEventsRepository implements HostEventsRepository {
  _FakeHostEventsRepository(this._result);
  final Result<HostEvent> _result;
  HostEvent? lastEvent;

  @override
  Future<Result<List<HostEvent>>> getEvents() => throw UnimplementedError();

  @override
  Future<Result<HostEvent>> getEventById(String eventId) =>
      throw UnimplementedError();

  @override
  Future<Result<HostEvent>> saveEvent(HostEvent event) async {
    lastEvent = event;
    return _result;
  }

  @override
  Future<Result<HostEventPhoto>> uploadEventPhoto({
    required String filePath,
    required String fileName,
  }) => throw UnimplementedError();
}

void main() {
  const event = HostEvent(
    id: '',
    title: 'Blind Wine & Bad Takes',
    description: 'Six wines, labels off.',
    format: 'Tasting',
    startAt: null,
    endAt: null,
    doorsOpenAt: null,
    venueId: 'venue-1',
    venueName: 'Toit, Indiranagar',
    venueAddress: '12, 100 Feet Road, Indiranagar, Bangalore',
    neighbourhood: 'Indiranagar',
    capacity: 40,
    ticketPriceRupees: 1299,
    toleranceBandPoints: 10,
    holdbackEnabled: false,
    cancellationTerms: 'No refunds within 24h of doors.',
    refundCutoffHoursBeforeStart: 24,
    coverPhoto: null,
    photos: [],
    status: HostEventLifecycleStatus.draft,
  );

  test(
    'passes the draft through to the repository and returns its result',
    () async {
      final saved = event.copyWith(id: 'event-1');
      final repository = _FakeHostEventsRepository(Ok(saved));
      final useCase = SaveHostEventUseCase(repository);

      final actual = await useCase(event);

      expect(repository.lastEvent, event);
      actual.when(
        ok: (value) => expect(value.id, 'event-1'),
        err: (_) => fail('expected Ok'),
      );
    },
  );

  test('surfaces a repository failure unchanged', () async {
    const failure = NetworkFailure(message: "Couldn't save event");
    final repository = _FakeHostEventsRepository(const Err(failure));
    final useCase = SaveHostEventUseCase(repository);

    final actual = await useCase(event);

    actual.when(
      ok: (_) => fail('expected Err'),
      err: (value) => expect(value.message, "Couldn't save event"),
    );
  });
}
