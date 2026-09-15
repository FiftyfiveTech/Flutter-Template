import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/base_api_client.dart';
import '../models/host_event_dto.dart';
import '../models/host_event_photo_dto.dart';

abstract class HostEventsRemoteDatasource {
  Future<HostEventDto> createEvent(HostEventDto event);

  Future<HostEventPhotoDto> uploadEventPhoto({
    required String filePath,
    required String fileName,
  });
}

/// Placeholder REST shape, mirroring `HostVenuesRestDatasource` before its
/// real contract existed — no backend endpoint spec for events exists yet.
class HostEventsRestDatasource implements HostEventsRemoteDatasource {
  HostEventsRestDatasource(this._client);

  final BaseApiClient _client;

  @override
  Future<HostEventDto> createEvent(HostEventDto event) async {
    // Intended endpoint: POST /api/v1/events
    final response = await _client.post('/api/v1/events', data: event.toJson());
    final body = response.data as Map<String, dynamic>;
    return HostEventDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<HostEventPhotoDto> uploadEventPhoto({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: _mediaTypeFor(fileName),
      ),
    });
    final response = await _client.post(
      '/api/v1/uploads',
      queryParameters: {'fileType': 'event_photo'},
      data: formData,
    );
    final body = response.data as Map<String, dynamic>;
    return HostEventPhotoDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  MediaType _mediaTypeFor(String fileName) {
    switch (p.extension(fileName).toLowerCase()) {
      case '.png':
        return MediaType('image', 'png');
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
