import '../../domain/entities/host_document_status.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_document_verification_status.dart';

/// One entry of the `data` array from `GET /api/v1/host/documents`.
class HostDocumentStatusDto {
  const HostDocumentStatusDto({
    required this.docType,
    required this.status,
    this.reason,
  });

  final String docType;
  final String status;
  final String? reason;

  factory HostDocumentStatusDto.fromJson(Map<String, dynamic> json) {
    return HostDocumentStatusDto(
      docType: json['docType'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String?,
    );
  }

  HostDocumentStatus toEntity() => HostDocumentStatus(
    docType: HostDocumentTypeLabel.fromSubmitDocType(docType),
    status: HostDocumentVerificationStatusParsing.fromApiValue(status),
    reason: reason,
  );
}
