import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_remote_datasource.dart';

class CityRepositoryImpl implements CityRepository {
  const CityRepositoryImpl(this._remoteDatasource);

  final CityRemoteDatasource _remoteDatasource;

  @override
  Future<Result<List<City>>> searchCities(String query) async {
    try {
      final dtos = await _remoteDatasource.searchCities(query);
      return Ok(dtos.map((dto) => dto.toEntity()).toList());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
