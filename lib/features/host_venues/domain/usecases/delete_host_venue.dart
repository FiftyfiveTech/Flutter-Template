import '../../../../core/error/result.dart';
import '../repositories/host_venues_repository.dart';

class DeleteHostVenueUseCase {
  const DeleteHostVenueUseCase(this._repository);

  final HostVenuesRepository _repository;

  Future<Result<void>> call(String venueId) => _repository.deleteVenue(venueId);
}
