import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event_photo.dart';
import 'package:host_mobile_app/features/host_events/domain/repositories/host_events_repository.dart';
import 'package:host_mobile_app/features/host_events/domain/usecases/upload_event_photo.dart';

class _FakeHostEventsRepository implements HostEventsRepository {
  _FakeHostEventsRepository(this._result);
  final Result<HostEventPhoto> _result;
  String? lastFilePath;
  String? lastFileName;

  @override
  Future<Result<HostEventPhoto>> uploadEventPhoto({
    required String filePath,
    required String fileName,
  }) async {
    lastFilePath = filePath;
    lastFileName = fileName;
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
}

void main() {
  test(
    'passes the file through to the repository and returns its result',
    () async {
      const photo = HostEventPhoto(id: 'p1', url: 'https://example.com/p1.jpg');
      final repository = _FakeHostEventsRepository(const Ok(photo));
      final useCase = UploadEventPhotoUseCase(repository);

      final actual = await useCase(
        filePath: '/tmp/photo.jpg',
        fileName: 'photo.jpg',
      );

      expect(repository.lastFilePath, '/tmp/photo.jpg');
      expect(repository.lastFileName, 'photo.jpg');
      actual.when(
        ok: (value) => expect(value.id, 'p1'),
        err: (_) => fail('expected Ok'),
      );
    },
  );

  test('surfaces a repository failure unchanged', () async {
    const failure = NetworkFailure(message: 'Upload failed');
    final repository = _FakeHostEventsRepository(const Err(failure));
    final useCase = UploadEventPhotoUseCase(repository);

    final actual = await useCase(
      filePath: '/tmp/photo.jpg',
      fileName: 'photo.jpg',
    );

    actual.when(
      ok: (_) => fail('expected Err'),
      err: (value) => expect(value.message, 'Upload failed'),
    );
  });
}
