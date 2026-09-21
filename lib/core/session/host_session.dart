/// The signed-in host session established once H-01 · Signup succeeds.
/// Persisted to Drift (`HostSessionTable`) via `HostSessionLocalDatasource`
/// so an app restart doesn't require signing in again mid-onboarding.
class HostSession {
  const HostSession({
    required this.accessToken,
    required this.userId,
    required this.accountStatus,
    this.businessName = '',
  });

  final String accessToken;
  final String userId;
  final String accountStatus;

  /// The business/organiser name entered at signup, if this session came
  /// from H-01 on this device — empty for a session restored via OTP
  /// login, since the backend doesn't return it there.
  final String businessName;
}
