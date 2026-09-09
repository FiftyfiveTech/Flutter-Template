import '../../../../core/network/base_api_client.dart';
import '../models/host_signup_dto.dart';

abstract interface class HostSignupRemoteDatasource {
  Future<HostSignupResponseDto> signup(HostSignupRequestDto request);
}

class HostSignupRestDatasource implements HostSignupRemoteDatasource {
  HostSignupRestDatasource(this._client);
  final BaseApiClient _client;

  @override
  Future<HostSignupResponseDto> signup(HostSignupRequestDto request) async {
    final response = await _client.post(
      '/api/v1/host/signup',
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return HostSignupResponseDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
