import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event_photo.dart';
import 'package:host_mobile_app/features/host_events/domain/repositories/host_events_repository.dart';
import 'package:host_mobile_app/features/host_events/domain/usecases/cancel_host_event.dart';
import 'package:host_mobile_app/features/host_events/domain/usecases/delete_host_event.dart';
import 'package:host_mobile_app/features/host_events/domain/usecases/submit_host_event.dart';

class _FakeHostEventsRepository implements HostEventsRepository {
  _FakeHostEventsRepository(this._result);
  final Result<HostEvent> _result;
  String? submittedId;
  String? cancelledId;
  String? cancelReason;
  String? deletedId;
  Result<void> deleteResult = const Ok(null);

  @override
  Future<Result<HostEvent>> submitEvent(String eventId) async {
    submittedId = eventId;
    return _result;
  }

  @override
  Future<Result<HostEvent>> cancelEvent(
    String eventId, {
    required String reason,
  }) async {
    cancelledId = eventId;
    cancelReason = reason;
    return _result;
  }

  @override
  Future<Result<List<HostEvent>>> getEvents() => throw UnimplementedError();

  @override
  Future<Result<HostEvent>> getEventById(String eventId) =>
      throw UnimplementedError();

  @override
  Future<Result<HostEvent>> saveEvent(HostEvent event) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteEvent(String eventId) async {
    deletedId = eventId;
    return deleteResult;
  }

  @override
  Future<Result<HostEventPhoto>> uploadEventPhoto({
    required String filePath,
    required String fileName,
  }) => throw UnimplementedError();
}

void main() {
  final submitted = HostEvent.empty.copyWith(
    id: 'event-1',
    status: HostEventLifecycleStatus.submitted,
  );

  group('SubmitHostEventUseCase', () {
    test('submits the given event id and returns the updated event', () async {
      final repository = _FakeHostEventsRepository(Ok(submitted));
      final result = await SubmitHostEventUseCase(repository)('event-1');

      expect(repository.submittedId, 'event-1');
      result.when(
        ok: (event) => expect(event.status, HostEventLifecycleStatus.submitted),
        err: (_) => fail('expected Ok'),
      );
    });

    test('surfaces a repository failure unchanged', () async {
      const failure = NetworkFailure(message: 'Submit failed');
      final repository = _FakeHostEventsRepository(const Err(failure));
      final result = await SubmitHostEventUseCase(repository)('event-1');

      result.when(
        ok: (_) => fail('expected Err'),
        err: (actual) => expect(actual, failure),
      );
    });
  });

  group('CancelHostEventUseCase', () {
    test('sends the trimmed reason', () async {
      final repository = _FakeHostEventsRepository(Ok(submitted));
      await CancelHostEventUseCase(repository)(
        'event-1',
        reason: '  Venue flooded  ',
      );

      expect(repository.cancelledId, 'event-1');
      expect(repository.cancelReason, 'Venue flooded');
    });

    test('rejects a blank reason without calling the repository', () async {
      final repository = _FakeHostEventsRepository(Ok(submitted));
      final result = await CancelHostEventUseCase(repository)(
        'event-1',
        reason: '   ',
      );

      expect(repository.cancelledId, isNull);
      result.when(
        ok: (_) => fail('expected Err'),
        err: (failure) => expect(failure, isA<ValidationFailure>()),
      );
    });

    test('rejects a reason over the max length', () async {
      final repository = _FakeHostEventsRepository(Ok(submitted));
      final result = await CancelHostEventUseCase(repository)(
        'event-1',
        reason: 'x' * (kMaxCancelReasonLength + 1),
      );

      expect(repository.cancelledId, isNull);
      result.when(
        ok: (_) => fail('expected Err'),
        err: (failure) => expect(failure, isA<ValidationFailure>()),
      );
    });
  });

  group('DeleteHostEventUseCase', () {
    test('deletes the given event id', () async {
      final repository = _FakeHostEventsRepository(Ok(submitted));
      final result = await DeleteHostEventUseCase(repository)('event-1');

      expect(repository.deletedId, 'event-1');
      expect(result.when(ok: (_) => true, err: (_) => false), isTrue);
    });

    test('surfaces a repository failure unchanged', () async {
      const failure = NetworkFailure(message: 'Delete failed');
      final repository = _FakeHostEventsRepository(Ok(submitted))
        ..deleteResult = const Err(failure);
      final result = await DeleteHostEventUseCase(repository)('event-1');

      result.when(
        ok: (_) => fail('expected Err'),
        err: (actual) => expect(actual, failure),
      );
    });
  });
}
