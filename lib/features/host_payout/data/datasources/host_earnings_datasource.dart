import '../../../../core/network/base_api_client.dart';
import '../models/host_earnings_dto.dart';

abstract interface class HostEarningsDatasource {
  /// `GET /api/v1/host/payouts/revenue/stats`.
  Future<HostEarningsDto> getRevenueStats();
}

class HostEarningsRestDatasource implements HostEarningsDatasource {
  HostEarningsRestDatasource(this._client);

  final BaseApiClient _client;

  @override
  Future<HostEarningsDto> getRevenueStats() async {
    final response = await _client.get('/api/v1/host/payouts/revenue/stats');
    final body = response.data as Map<String, dynamic>;
    return HostEarningsDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
