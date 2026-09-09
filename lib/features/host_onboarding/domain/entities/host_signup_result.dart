/// What the signup API returns on success: a session for the newly created
/// host account.
class HostSignupResult {
  const HostSignupResult({
    required this.accessToken,
    required this.userId,
    required this.accountStatus,
  });

  final String accessToken;
  final String userId;
  final String accountStatus;
}
