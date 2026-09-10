/// Per-document review outcome from `GET /api/v1/host/documents`.
enum HostDocumentVerificationStatus { pending, verified, rejected }

extension HostDocumentVerificationStatusParsing
    on HostDocumentVerificationStatus {
  static HostDocumentVerificationStatus fromApiValue(String value) {
    return switch (value) {
      'verified' => HostDocumentVerificationStatus.verified,
      'rejected' => HostDocumentVerificationStatus.rejected,
      _ => HostDocumentVerificationStatus.pending,
    };
  }
}
