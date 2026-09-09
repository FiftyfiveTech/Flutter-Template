/// Server-side outcome of uploading one document for H-03 · Documents.
class HostDocumentUploadResult {
  const HostDocumentUploadResult({
    required this.documentId,
    required this.status,
  });

  final String documentId;
  final String status;
}
