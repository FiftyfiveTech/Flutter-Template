import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/network/base_api_client.dart';
import 'package:host_mobile_app/features/host_venues/data/datasources/host_venues_remote_datasource.dart';
import 'package:host_mobile_app/features/host_venues/data/models/host_venue_dto.dart';
import 'package:host_mobile_app/features/host_venues/data/models/host_venue_photo_dto.dart';
import 'package:host_mobile_app/features/host_venues/data/repository_impl/host_venues_repository_impl.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue_photo.dart';

class _FakeRemoteDatasource implements HostVenuesRemoteDatasource {
  _FakeRemoteDatasource();

  Object? getByIdError;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  Object? uploadError;

  HostVenueDto? venueToReturn;
  HostVenuePhotoDto? photoToReturn;
  String? lastUpdatedVenueId;

  @override
  Future<List<HostVenueDto>> getVenues() async => [];

  @override
  Future<HostVenueDto> getVenueById(String venueId) async {
    if (getByIdError != null) throw getByIdError!;
    return venueToReturn!;
  }

  @override
  Future<HostVenueDto> createVenue(HostVenueDto venue) async {
    if (createError != null) throw createError!;
    return venueToReturn!;
  }

  @override
  Future<HostVenueDto> updateVenue(String venueId, HostVenueDto venue) async {
    lastUpdatedVenueId = venueId;
    if (updateError != null) throw updateError!;
    return venueToReturn!;
  }

  @override
  Future<void> deleteVenue(String venueId) async {
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<HostVenuePhotoDto> uploadVenuePhoto({
    required String filePath,
    required String fileName,
  }) async {
    if (uploadError != null) throw uploadError!;
    return photoToReturn!;
  }
}

void main() {
  const venueDto = HostVenueDto(
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
    photos: [],
  );

  const draft = HostVenue(
    id: '',
    name: 'Toit, Indiranagar',
    addLine1: '12, 100 Feet Road',
    addLine2: '',
    locality: 'Indiranagar',
    cityId: '507f1f77bcf86cd799439011',
    cityName: 'Bangalore',
    pincode: '560038',
    maxCapacity: 40,
    allowedVenueTypes: ['Restaurant'],
    photos: [],
  );

  test('getVenueById maps a NetworkException to a NetworkFailure', () async {
    final datasource = _FakeRemoteDatasource()
      ..getByIdError = NetworkException('offline');
    final repository = HostVenuesRepositoryImpl(datasource);

    final result = await repository.getVenueById('venue-1');

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'offline');
      },
    );
  });

  test('getVenueById maps an unexpected error to UnexpectedFailure', () async {
    final datasource = _FakeRemoteDatasource()
      ..getByIdError = Exception('boom');
    final repository = HostVenuesRepositoryImpl(datasource);

    final result = await repository.getVenueById('venue-1');

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) => expect(failure, isA<UnexpectedFailure>()),
    );
  });

  test('saveVenue creates when the draft has no id', () async {
    final datasource = _FakeRemoteDatasource()..venueToReturn = venueDto;
    final repository = HostVenuesRepositoryImpl(datasource);

    final result = await repository.saveVenue(draft);

    expect(datasource.lastUpdatedVenueId, isNull);
    result.when(
      ok: (venue) => expect(venue.id, 'venue-1'),
      err: (_) => fail('expected Ok'),
    );
  });

  test(
    'saveVenue updates the existing id when the draft already has one',
    () async {
      final datasource = _FakeRemoteDatasource()..venueToReturn = venueDto;
      final repository = HostVenuesRepositoryImpl(datasource);

      await repository.saveVenue(draft.copyWith(id: 'venue-1'));

      expect(datasource.lastUpdatedVenueId, 'venue-1');
    },
  );

  test('uploadVenuePhoto returns the uploaded photo on success', () async {
    const photoDto = HostVenuePhotoDto(
      id: 'p1',
      url: 'https://example.com/p1.jpg',
    );
    final datasource = _FakeRemoteDatasource()..photoToReturn = photoDto;
    final repository = HostVenuesRepositoryImpl(datasource);

    final result = await repository.uploadVenuePhoto(
      filePath: '/tmp/photo.jpg',
      fileName: 'photo.jpg',
    );

    result.when(
      ok: (photo) {
        expect(photo, isA<HostVenuePhoto>());
        expect(photo.id, 'p1');
      },
      err: (_) => fail('expected Ok'),
    );
  });

  test('deleteVenue maps a NetworkException to a NetworkFailure', () async {
    final datasource = _FakeRemoteDatasource()
      ..deleteError = NetworkException('offline');
    final repository = HostVenuesRepositoryImpl(datasource);

    final result = await repository.deleteVenue('venue-1');

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) => expect(failure, isA<NetworkFailure>()),
    );
  });
}
