import '../../../../core/network/base_api_client.dart';
import '../models/host_login_dto.dart';

abstract interface class HostLoginRemoteDatasource {
  Future<void> requestOtp(OtpRequestDto request);

  Future<OtpVerifyResponseDto> verifyOtp(OtpVerifyRequestDto request);
}

class HostLoginRestDatasource implements HostLoginRemoteDatasource {
  HostLoginRestDatasource(this._client);
  final BaseApiClient _client;

  @override
  Future<void> requestOtp(OtpRequestDto request) async {
    await _client.post('/api/v1/host/auth/otp/request', data: request.toJson());
  }

  @override
  Future<OtpVerifyResponseDto> verifyOtp(OtpVerifyRequestDto request) async {
    final response = await _client.post(
      '/api/v1/host/auth/otp/verify',
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return OtpVerifyResponseDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
