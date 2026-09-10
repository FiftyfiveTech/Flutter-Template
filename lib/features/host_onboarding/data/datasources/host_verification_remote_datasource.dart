import '../../../../core/network/base_api_client.dart';
import '../models/host_verification_submission_dto.dart';

abstract interface class HostVerificationRemoteDatasource {
  Future<HostVerificationSubmissionResponseDto> submit(
    HostVerificationSubmissionRequestDto request,
  );
}

class HostVerificationRestDatasource
    implements HostVerificationRemoteDatasource {
  HostVerificationRestDatasource(this._client);
  final BaseApiClient _client;

  @override
  Future<HostVerificationSubmissionResponseDto> submit(
    HostVerificationSubmissionRequestDto request,
  ) async {
    final response = await _client.post(
      '/api/v1/host/submit-verification',
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return HostVerificationSubmissionResponseDto.fromJson(body);
  }
}
