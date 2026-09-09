import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_document_upload_result.dart';
import '../../domain/repositories/host_document_repository.dart';
import '../datasources/host_document_remote_datasource.dart';

class HostDocumentRepositoryImpl implements HostDocumentRepository {
  const HostDocumentRepositoryImpl(this._remoteDatasource);

  final HostDocumentRemoteDatasource _remoteDatasource;

  @override
  Future<Result<HostDocumentUploadResult>> uploadDocument({
    required HostDocumentType documentType,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final response = await _remoteDatasource.uploadDocument(
        documentType: documentType,
        filePath: filePath,
        fileName: fileName,
      );
      return Ok(response.toEntity());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
