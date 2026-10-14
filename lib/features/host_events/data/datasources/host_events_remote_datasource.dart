import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/base_api_client.dart';
import '../models/host_event_dto.dart';
import '../models/host_event_photo_dto.dart';

abstract class HostEventsRemoteDatasource {
  Future<List<HostEventDto>> getEvents();

  Future<HostEventDto> getEventById(String eventId);

  Future<HostEventDto> createEvent(HostEventDto event);

  Future<HostEventDto> updateEvent(String eventId, HostEventDto event);

  Future<HostEventDto> submitEvent(String eventId);

  Future<HostEventDto> cancelEvent(String eventId, {required String reason});

  Future<HostEventPhotoDto> uploadEventPhoto({
    required String filePath,
    required String fileName,
  });
}

class HostEventsRestDatasource implements HostEventsRemoteDatasource {
  HostEventsRestDatasource(this._client);

  final BaseApiClient _client;

  @override
  Future<List<HostEventDto>> getEvents() async {
    final response = await _client.get('/api/v1/host/events');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => HostEventDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HostEventDto> getEventById(String eventId) async {
    final response = await _client.get('/api/v1/host/events/$eventId');
    final body = response.data as Map<String, dynamic>;
    return HostEventDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<HostEventDto> createEvent(HostEventDto event) async {
    final response = await _client.post(
      '/api/v1/host/events',
      data: event.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return HostEventDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<HostEventDto> updateEvent(String eventId, HostEventDto event) async {
    final response = await _client.patch(
      '/api/v1/host/events/$eventId',
      data: event.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return HostEventDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<HostEventDto> submitEvent(String eventId) async {
    final response = await _client.post('/api/v1/host/events/$eventId/submit');
    final body = response.data as Map<String, dynamic>;
    return HostEventDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<HostEventDto> cancelEvent(
    String eventId, {
    required String reason,
  }) async {
    final response = await _client.post(
      '/api/v1/host/events/$eventId/cancel',
      data: {'reason': reason},
    );
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
      // Same fileType for both the cover image and gallery photos.
      queryParameters: {'fileType': 'event_cover_media'},
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
      case '.webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
