import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue_photo.dart';
import 'package:host_mobile_app/features/host_venues/domain/repositories/host_venues_repository.dart';
import 'package:host_mobile_app/features/host_venues/domain/usecases/upload_venue_photo.dart';

class _FakeHostVenuesRepository implements HostVenuesRepository {
  _FakeHostVenuesRepository(this._result);
  final Result<HostVenuePhoto> _result;
  String? lastFilePath;
  String? lastFileName;

  @override
  Future<Result<HostVenuePhoto>> uploadVenuePhoto({
    required String filePath,
    required String fileName,
  }) async {
    lastFilePath = filePath;
    lastFileName = fileName;
    return _result;
  }

  @override
  Future<Result<HostVenue>> getVenueById(String venueId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<HostVenue>>> getVenues() => throw UnimplementedError();

  @override
  Future<Result<HostVenue>> saveVenue(HostVenue venue) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteVenue(String venueId) =>
      throw UnimplementedError();
}

void main() {
  test(
    'passes the file through to the repository and returns its result',
    () async {
      const photo = HostVenuePhoto(id: 'p1', url: 'https://example.com/p1.jpg');
      final repository = _FakeHostVenuesRepository(const Ok(photo));
      final useCase = UploadVenuePhotoUseCase(repository);

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
    final repository = _FakeHostVenuesRepository(const Err(failure));
    final useCase = UploadVenuePhotoUseCase(repository);

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
