/// The `data` object of a successful OTP verification — mints a session
/// exactly like `HostSignupResult` does for signup.
class HostLoginResult {
  const HostLoginResult({
    required this.accessToken,
    required this.userId,
    required this.accountStatus,
  });

  final String accessToken;
  final String userId;
  final String accountStatus;
}
