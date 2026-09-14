/// Per-document review outcome from `GET /api/v1/host/documents`.
enum HostDocumentVerificationStatus { pending, approved, rejected }

extension HostDocumentVerificationStatusParsing
    on HostDocumentVerificationStatus {
  static HostDocumentVerificationStatus fromApiValue(String value) {
    return switch (value) {
      'approved' => HostDocumentVerificationStatus.approved,
      'rejected' => HostDocumentVerificationStatus.rejected,
      _ => HostDocumentVerificationStatus.pending,
    };
  }
}
