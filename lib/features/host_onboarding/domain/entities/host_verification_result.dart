/// What the submit-verification API returns on success: the host
/// account's status once under review (e.g. `pending_review`).
class HostVerificationResult {
  const HostVerificationResult({required this.accountStatus});

  final String accountStatus;
}
