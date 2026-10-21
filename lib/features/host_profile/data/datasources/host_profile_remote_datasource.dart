import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/base_api_client.dart';
import '../models/host_profile_dto.dart';

abstract interface class HostProfileRemoteDatasource {
  /// `POST /api/v1/uploads?fileType=profile_photo`.
  Future<HostProfileUploadDto> uploadPhoto(String filePath);

  /// `PATCH /api/v1/host/profile`.
  Future<HostProfileResponseDto> updateProfile(
    UpdateHostProfileRequestDto request,
  );

  /// `DELETE /api/v1/host/me` — soft-deletes the signed-in host account.
  Future<void> deleteAccount();
}

class HostProfileRestDatasource implements HostProfileRemoteDatasource {
  HostProfileRestDatasource(this._client);

  final BaseApiClient _client;

  @override
  Future<HostProfileUploadDto> uploadPhoto(String filePath) async {
    final fileName = p.basename(filePath);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: _mediaTypeFor(fileName),
      ),
    });
    final response = await _client.post(
      '/api/v1/uploads',
      queryParameters: {'fileType': 'profile_photo'},
      data: formData,
    );
    final body = response.data as Map<String, dynamic>;
    return HostProfileUploadDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<HostProfileResponseDto> updateProfile(
    UpdateHostProfileRequestDto request,
  ) async {
    final response = await _client.patch(
      '/api/v1/host/profile',
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return HostProfileResponseDto.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _client.delete('/api/v1/host/me');
  }

  MediaType _mediaTypeFor(String fileName) {
    switch (p.extension(fileName).toLowerCase()) {
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.heic':
        return MediaType('image', 'heic');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
