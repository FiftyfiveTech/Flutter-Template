import '../../../../core/error/result.dart';
import '../entities/host_venue.dart';
import '../repositories/host_venues_repository.dart';

class GetHostVenuesUseCase {
  const GetHostVenuesUseCase(this._repository);

  final HostVenuesRepository _repository;

  Future<Result<List<HostVenue>>> call() => _repository.getVenues();
}
