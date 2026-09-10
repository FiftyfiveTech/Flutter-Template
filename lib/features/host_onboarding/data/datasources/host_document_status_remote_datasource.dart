import '../../../../core/network/base_api_client.dart';
import '../models/host_document_status_dto.dart';

abstract interface class HostDocumentStatusRemoteDatasource {
  Future<List<HostDocumentStatusDto>> getDocumentsStatus();
}

class HostDocumentStatusRestDatasource
    implements HostDocumentStatusRemoteDatasource {
  HostDocumentStatusRestDatasource(this._client);
  final BaseApiClient _client;

  @override
  Future<List<HostDocumentStatusDto>> getDocumentsStatus() async {
    final response = await _client.get('/api/v1/host/documents');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .map(
          (json) =>
              HostDocumentStatusDto.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }
}
