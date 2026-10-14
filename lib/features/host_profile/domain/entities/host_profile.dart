/// The signed-in host's profile as last seen on this device — cached so
/// the You tab (H-12) renders fully offline, including the avatar.
///
/// [photoPath] points at a copy of the host's chosen avatar inside the
/// app's private documents directory (never the picker's original path),
/// so it survives restarts and works without a connection. `null` when
/// no avatar has been picked yet — the UI falls back to initials.
class HostProfile {
  const HostProfile({
    required this.userId,
    this.hostName = '',
    this.isVerified = false,
    this.savedVenuesCount = 0,
    this.photoPath,
  });

  final String userId;
  final String hostName;
  final bool isVerified;
  final int savedVenuesCount;
  final String? photoPath;

  HostProfile copyWith({
    String? hostName,
    bool? isVerified,
    int? savedVenuesCount,
    String? photoPath,
  }) {
    return HostProfile(
      userId: userId,
      hostName: hostName ?? this.hostName,
      isVerified: isVerified ?? this.isVerified,
      savedVenuesCount: savedVenuesCount ?? this.savedVenuesCount,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
