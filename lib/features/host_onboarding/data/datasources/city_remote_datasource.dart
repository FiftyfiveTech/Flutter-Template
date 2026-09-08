import '../../../../core/network/base_api_client.dart';
import '../models/city_dto.dart';

abstract interface class CityRemoteDatasource {
  Future<List<CityDto>> searchCities(String query);
}

class CityRestDatasource implements CityRemoteDatasource {
  CityRestDatasource(this._client);
  final BaseApiClient _client;

  @override
  Future<List<CityDto>> searchCities(String query) async {
    final response = await _client.get(
      '/api/v1/cities',
      queryParameters: {'search': query},
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .map((json) => CityDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
