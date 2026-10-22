/// The signed-in host's profile as last seen on this device — cached so
/// the You tab (H-12) renders fully offline, including the avatar.
///
/// [photoPath] points at a copy of the host's avatar (picked here, or
/// downloaded once from the server's presigned URL) inside the
/// app's private documents directory (never the picker's original path),
/// so it survives restarts and works without a connection. `null` when
/// no avatar has been picked yet — the UI falls back to initials.
///
/// [firstName]/[lastName] come from `GET /api/v1/host` (or the last Edit
/// profile save) — `null` until the profile has been fetched once.
class HostProfile {
  const HostProfile({
    required this.userId,
    this.hostName = '',
    this.firstName,
    this.lastName,
    this.isVerified = false,
    this.savedVenuesCount = 0,
    this.photoPath,
  });

  final String userId;
  final String hostName;
  final String? firstName;
  final String? lastName;
  final bool isVerified;
  final int savedVenuesCount;
  final String? photoPath;

  HostProfile copyWith({
    String? hostName,
    String? firstName,
    String? lastName,
    bool? isVerified,
    int? savedVenuesCount,
    String? photoPath,
  }) {
    return HostProfile(
      userId: userId,
      hostName: hostName ?? this.hostName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isVerified: isVerified ?? this.isVerified,
      savedVenuesCount: savedVenuesCount ?? this.savedVenuesCount,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
