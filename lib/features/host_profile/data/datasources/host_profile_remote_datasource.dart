import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/base_api_client.dart';
import '../models/host_profile_dto.dart';

abstract interface class HostProfileRemoteDatasource {
  /// `GET /api/v1/host` — the signed-in host's profile.
  Future<HostProfileResponseDto> getProfile();

  /// `POST /api/v1/uploads?fileType=profile_photo`.
  Future<HostProfileUploadDto> uploadPhoto(String filePath);

  /// `PATCH /api/v1/host/profile`.
  Future<HostProfileResponseDto> updateProfile(
    UpdateHostProfileRequestDto request,
  );

  /// `DELETE /api/v1/host/me` — soft-deletes the signed-in host account.
  Future<void> deleteAccount();

  /// Downloads the avatar at a presigned [url] to a temporary file and
  /// returns its path.
  Future<String> downloadPhoto(String url);
}

class HostProfileRestDatasource implements HostProfileRemoteDatasource {
  HostProfileRestDatasource(this._client, {Dio? downloader})
    : _downloader = downloader ?? Dio();

  final BaseApiClient _client;

  /// A plain client for presigned storage URLs: the API client's bearer
  /// token must not be sent there (storage rejects a request carrying
  /// both a signature and an Authorization header).
  final Dio _downloader;

  @override
  Future<HostProfileResponseDto> getProfile() async {
    final response = await _client.get('/api/v1/host');
    final body = response.data as Map<String, dynamic>;
    return HostProfileResponseDto.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

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

  @override
  Future<String> downloadPhoto(String url) async {
    final temp = await getTemporaryDirectory();
    final target = p.join(
      temp.path,
      'avatar_download_${DateTime.now().millisecondsSinceEpoch}',
    );
    await _downloader.download(url, target);
    return target;
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
