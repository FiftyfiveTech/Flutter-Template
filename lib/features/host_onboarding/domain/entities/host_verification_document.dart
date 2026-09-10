import 'host_document_type.dart';

/// One entry of the `documents` array sent to
/// `POST /api/v1/host/submit-verification`. `uploadId` is the
/// `documentId` returned by the H-03 upload call for this slot.
class HostVerificationDocument {
  const HostVerificationDocument({
    required this.docType,
    required this.uploadId,
    this.issuedAt,
    this.expiresAt,
  });

  final HostDocumentType docType;
  final String uploadId;

  /// Only set for licence-backed documents (FSSAI, state excise).
  final DateTime? issuedAt;
  final DateTime? expiresAt;
}
