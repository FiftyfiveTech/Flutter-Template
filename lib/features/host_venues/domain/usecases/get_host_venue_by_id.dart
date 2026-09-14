import '../../../../core/error/result.dart';
import '../entities/host_venue.dart';
import '../repositories/host_venues_repository.dart';

class GetHostVenueByIdUseCase {
  const GetHostVenueByIdUseCase(this._repository);

  final HostVenuesRepository _repository;

  Future<Result<HostVenue>> call(String venueId) =>
      _repository.getVenueById(venueId);
}
