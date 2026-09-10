import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_document_status.dart';
import '../../domain/repositories/host_document_status_repository.dart';
import '../datasources/host_document_status_remote_datasource.dart';

class HostDocumentStatusRepositoryImpl implements HostDocumentStatusRepository {
  const HostDocumentStatusRepositoryImpl(this._remoteDatasource);

  final HostDocumentStatusRemoteDatasource _remoteDatasource;

  @override
  Future<Result<List<HostDocumentStatus>>> getDocumentsStatus() async {
    try {
      final response = await _remoteDatasource.getDocumentsStatus();
      return Ok(response.map((dto) => dto.toEntity()).toList());
    } on NetworkException catch (e) {
      return Err(NetworkFailure(message: e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
