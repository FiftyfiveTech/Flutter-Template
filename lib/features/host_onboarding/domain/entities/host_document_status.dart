import 'host_document_type.dart';
import 'host_document_verification_status.dart';

/// One entry of `GET /api/v1/host/documents` — where a single uploaded
/// document stands in manual review.
class HostDocumentStatus {
  const HostDocumentStatus({
    required this.docType,
    required this.status,
    this.reason,
  });

  /// `null` when the backend returns a `docType` the client doesn't
  /// recognize (see [HostDocumentType.fromSubmitDocType]) — the row is
  /// still shown, just without a friendly label.
  final HostDocumentType? docType;
  final HostDocumentVerificationStatus status;

  /// Set when [status] is [HostDocumentVerificationStatus.rejected].
  final String? reason;
}
