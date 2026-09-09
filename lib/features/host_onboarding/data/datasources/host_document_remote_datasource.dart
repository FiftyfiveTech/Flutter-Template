import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_document_type.dart';
import '../models/host_document_dto.dart';

abstract interface class HostDocumentRemoteDatasource {
  Future<HostDocumentUploadResponseDto> uploadDocument({
    required HostDocumentType documentType,
    required String filePath,
    required String fileName,
  });
}

class HostDocumentRestDatasource implements HostDocumentRemoteDatasource {
  HostDocumentRestDatasource(this._client);
  final BaseApiClient _client;

  @override
  Future<HostDocumentUploadResponseDto> uploadDocument({
    required HostDocumentType documentType,
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
      queryParameters: {'fileType': documentType.apiValue},
      data: formData,
    );
    final body = response.data as Map<String, dynamic>;
    return HostDocumentUploadResponseDto.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  MediaType _mediaTypeFor(String fileName) {
    switch (p.extension(fileName).toLowerCase()) {
      case '.png':
        return MediaType('image', 'png');
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
