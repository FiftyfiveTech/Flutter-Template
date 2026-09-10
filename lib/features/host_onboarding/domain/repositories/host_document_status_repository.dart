import '../../../../core/error/result.dart';
import '../entities/host_document_status.dart';

abstract interface class HostDocumentStatusRepository {
  Future<Result<List<HostDocumentStatus>>> getDocumentsStatus();
}
