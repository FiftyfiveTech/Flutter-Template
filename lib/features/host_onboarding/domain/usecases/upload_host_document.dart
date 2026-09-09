import '../../../../core/error/result.dart';
import '../entities/host_document_type.dart';
import '../entities/host_document_upload_result.dart';
import '../repositories/host_document_repository.dart';

class UploadHostDocumentUseCase {
  const UploadHostDocumentUseCase(this._repository);
  final HostDocumentRepository _repository;

  Future<Result<HostDocumentUploadResult>> call({
    required HostDocumentType documentType,
    required String filePath,
    required String fileName,
  }) {
    return _repository.uploadDocument(
      documentType: documentType,
      filePath: filePath,
      fileName: fileName,
    );
  }
}
