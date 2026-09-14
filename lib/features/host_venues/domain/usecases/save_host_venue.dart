import '../../../../core/error/result.dart';
import '../entities/host_venue.dart';
import '../repositories/host_venues_repository.dart';

class SaveHostVenueUseCase {
  const SaveHostVenueUseCase(this._repository);

  final HostVenuesRepository _repository;

  Future<Result<HostVenue>> call(HostVenue venue) =>
      _repository.saveVenue(venue);
}
