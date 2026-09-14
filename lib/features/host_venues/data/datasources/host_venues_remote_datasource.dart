import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/base_api_client.dart';
import '../models/host_venue_dto.dart';
import '../models/host_venue_photo_dto.dart';

abstract class HostVenuesRemoteDatasource {
  Future<List<HostVenueDto>> getVenues();

  Future<HostVenueDto> getVenueById(String venueId);

  Future<HostVenueDto> createVenue(HostVenueDto venue);

  Future<HostVenueDto> updateVenue(String venueId, HostVenueDto venue);

  Future<void> deleteVenue(String venueId);

  Future<HostVenuePhotoDto> uploadVenuePhoto({
    required String filePath,
    required String fileName,
  });
}

class HostVenuesRestDatasource implements HostVenuesRemoteDatasource {
  HostVenuesRestDatasource(this._client);

  final BaseApiClient _client;

  @override
  Future<List<HostVenueDto>> getVenues() async {
    final response = await _client.get('/api/v1/venues');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => HostVenueDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HostVenueDto> getVenueById(String venueId) async {
    final response = await _client.get('/api/v1/venues/$venueId');
    final body = response.data as Map<String, dynamic>;
    return HostVenueDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<HostVenueDto> createVenue(HostVenueDto venue) async {
    final response = await _client.post('/api/v1/venues', data: venue.toJson());
    final body = response.data as Map<String, dynamic>;
    return HostVenueDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<HostVenueDto> updateVenue(String venueId, HostVenueDto venue) async {
    final response = await _client.patch(
      '/api/v1/venues/$venueId',
      data: venue.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return HostVenueDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteVenue(String venueId) async {
    await _client.delete('/api/v1/venues/$venueId');
  }

  @override
  Future<HostVenuePhotoDto> uploadVenuePhoto({
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
      queryParameters: {'fileType': 'venue_photo'},
      data: formData,
    );
    final body = response.data as Map<String, dynamic>;
    return HostVenuePhotoDto.fromJson(body['data'] as Map<String, dynamic>);
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
