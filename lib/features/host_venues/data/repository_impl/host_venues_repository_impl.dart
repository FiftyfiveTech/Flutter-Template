import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_venue.dart';
import '../../domain/entities/host_venue_photo.dart';
import '../../domain/repositories/host_venues_repository.dart';
import '../datasources/host_venues_remote_datasource.dart';
import '../models/host_venue_dto.dart';

class HostVenuesRepositoryImpl implements HostVenuesRepository {
  const HostVenuesRepositoryImpl(this._remoteDatasource);

  final HostVenuesRemoteDatasource _remoteDatasource;

  @override
  Future<Result<List<HostVenue>>> getVenues() async {
    try {
      final dtos = await _remoteDatasource.getVenues();
      return Ok(dtos.map((dto) => dto.toDomain()).toList());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostVenue>> getVenueById(String venueId) async {
    try {
      final dto = await _remoteDatasource.getVenueById(venueId);
      return Ok(dto.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostVenue>> saveVenue(HostVenue venue) async {
    try {
      final dto = HostVenueDto.fromDomain(venue);
      final saved = venue.id.isEmpty
          ? await _remoteDatasource.createVenue(dto)
          : await _remoteDatasource.updateVenue(venue.id, dto);
      return Ok(saved.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> deleteVenue(String venueId) async {
    try {
      await _remoteDatasource.deleteVenue(venueId);
      return const Ok(null);
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<HostVenuePhoto>> uploadVenuePhoto({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final dto = await _remoteDatasource.uploadVenuePhoto(
        filePath: filePath,
        fileName: fileName,
      );
      return Ok(dto.toDomain());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
