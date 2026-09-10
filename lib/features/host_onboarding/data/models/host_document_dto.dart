import '../../domain/entities/host_document_upload_result.dart';

/// The `data` object of a successful `POST /api/v1/uploads` response.
class HostDocumentUploadResponseDto {
  const HostDocumentUploadResponseDto({
    required this.documentId,
    required this.status,
  });

  final String documentId;
  final String status;

  factory HostDocumentUploadResponseDto.fromJson(Map<String, dynamic> json) {
    return HostDocumentUploadResponseDto(
      documentId: (json['documentId'] ?? json['id']).toString(),
      status: (json['status'] ?? 'UPLOADED').toString(),
    );
  }

  HostDocumentUploadResult toEntity() =>
      HostDocumentUploadResult(documentId: documentId, status: status);
}
