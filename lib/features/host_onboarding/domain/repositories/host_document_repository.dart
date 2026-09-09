import '../../../../core/error/result.dart';
import '../entities/host_document_type.dart';
import '../entities/host_document_upload_result.dart';

abstract interface class HostDocumentRepository {
  /// Uploads the file at [filePath] for [documentType]. The file is read
  /// from disk at call time and never routed through a domain entity —
  /// see `HostDocumentSelection`'s doc comment on why raw bytes stay out
  /// of the model layer.
  Future<Result<HostDocumentUploadResult>> uploadDocument({
    required HostDocumentType documentType,
    required String filePath,
    required String fileName,
  });
}
