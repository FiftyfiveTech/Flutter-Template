import '../../../../core/error/result.dart';
import '../entities/host_venue.dart';
import '../entities/host_venue_photo.dart';

abstract class HostVenuesRepository {
  Future<Result<List<HostVenue>>> getVenues();

  Future<Result<HostVenue>> getVenueById(String venueId);

  Future<Result<HostVenue>> saveVenue(HostVenue venue);

  Future<Result<void>> deleteVenue(String venueId);

  Future<Result<HostVenuePhoto>> uploadVenuePhoto({
    required String filePath,
    required String fileName,
  });
}
