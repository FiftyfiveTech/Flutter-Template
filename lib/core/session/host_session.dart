/// The signed-in host session established once H-01 · Signup succeeds.
/// Persisted to Drift (`HostSessionTable`) via `HostSessionLocalDatasource`
/// so an app restart doesn't require signing in again mid-onboarding.
class HostSession {
  const HostSession({
    required this.accessToken,
    required this.userId,
    required this.accountStatus,
  });

  final String accessToken;
  final String userId;
  final String accountStatus;
}
