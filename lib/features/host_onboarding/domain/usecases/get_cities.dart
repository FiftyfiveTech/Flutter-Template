import '../../../../core/error/result.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

/// Fetches the full city list once for the H-01 signup and H-07 venue
/// "City" fields — the dropdown then filters this cached list locally as
/// the host types, rather than re-querying the backend per keystroke.
class GetCitiesUseCase {
  const GetCitiesUseCase(this._repository);

  final CityRepository _repository;

  Future<Result<List<City>>> call() {
    return _repository.getCities();
  }
}
