import '../../../../core/error/result.dart';
import '../entities/city.dart';

abstract interface class CityRepository {
  Future<Result<List<City>>> searchCities(String query);
}
