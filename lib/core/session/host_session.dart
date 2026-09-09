/// The signed-in host session established once H-01 · Signup succeeds.
/// Held in memory only for now — no secure-storage persistence yet, so a
/// process restart requires signing in again.
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
