/// What the submit-verification API returns on success — just a
/// confirmation message, no `accountStatus`; the real per-document
/// status comes from `GET /api/v1/host/documents` (H-04's status poll).
class HostVerificationResult {
  const HostVerificationResult({required this.message});

  final String message;
}
