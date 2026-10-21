import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue_photo.dart';
import 'package:host_mobile_app/features/host_venues/domain/repositories/host_venues_repository.dart';
import 'package:host_mobile_app/features/host_venues/domain/usecases/get_host_venue_by_id.dart';

class _FakeHostVenuesRepository implements HostVenuesRepository {
  _FakeHostVenuesRepository(this._result);
  final Result<HostVenue> _result;
  String? lastVenueId;

  @override
  Future<Result<HostVenue>> getVenueById(String venueId) async {
    lastVenueId = venueId;
    return _result;
  }

  @override
  Future<Result<List<HostVenue>>> getVenues() => throw UnimplementedError();

  @override
  Future<Result<HostVenue>> saveVenue(HostVenue venue) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteVenue(String venueId) =>
      throw UnimplementedError();

  @override
  Future<Result<HostVenuePhoto>> uploadVenuePhoto({
    required String filePath,
    required String fileName,
  }) => throw UnimplementedError();
}

void main() {
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
    photos: [HostVenuePhoto(id: 'p1', url: 'https://example.com/p1.jpg')],
  );

  test(
    'passes the id through to the repository and returns its result',
    () async {
      final repository = _FakeHostVenuesRepository(const Ok(venue));
      final useCase = GetHostVenueByIdUseCase(repository);

      final actual = await useCase('venue-1');

      expect(repository.lastVenueId, 'venue-1');
      actual.when(
        ok: (value) => expect(value.id, 'venue-1'),
        err: (_) => fail('expected Ok'),
      );
    },
  );

  test('surfaces a repository failure unchanged', () async {
    const failure = NetworkFailure(message: "Couldn't load venue");
    final repository = _FakeHostVenuesRepository(const Err(failure));
    final useCase = GetHostVenueByIdUseCase(repository);

    final actual = await useCase('venue-1');

    actual.when(
      ok: (_) => fail('expected Err'),
      err: (value) => expect(value.message, "Couldn't load venue"),
    );
  });
}
