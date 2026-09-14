import '../../../../core/error/result.dart';
import '../entities/host_venue.dart';

abstract class HostVenuesRepository {
  Future<Result<List<HostVenue>>> getVenues();

  Future<Result<HostVenue>> saveVenue(HostVenue venue);

  Future<Result<void>> deleteVenue(String venueId);
}
