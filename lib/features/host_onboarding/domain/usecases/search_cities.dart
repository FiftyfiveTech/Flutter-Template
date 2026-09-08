import '../../../../core/error/result.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

/// Looks up cities by name for the H-01 signup "City" typeahead.
class SearchCitiesUseCase {
  const SearchCitiesUseCase(this._repository);

  final CityRepository _repository;

  Future<Result<List<City>>> call(String query) {
    return _repository.searchCities(query);
  }
}
