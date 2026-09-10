import '../../../../core/error/result.dart';
import '../entities/host_document_status.dart';
import '../repositories/host_document_status_repository.dart';

/// Fetches where every submitted document stands in manual review, for
/// H-04 · Verification to poll on load and on pull-to-refresh.
class GetHostDocumentsStatusUseCase {
  const GetHostDocumentsStatusUseCase(this._repository);

  final HostDocumentStatusRepository _repository;

  Future<Result<List<HostDocumentStatus>>> call() {
    return _repository.getDocumentsStatus();
  }
}
