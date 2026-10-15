/// One guest in the signed offline manifest. The QR itself is never in
/// the manifest, only its SHA-256 hash, matched against a scanned code.
class CheckInManifestAttendee {
  const CheckInManifestAttendee({
    required this.bookingId,
    required this.userId,
    required this.firstName,
    required this.qrCodeHash,
    required this.alreadyCheckedIn,
    this.photoUrl,
  });

  final String bookingId;
  final String userId;
  final String firstName;
  final String? photoUrl;
  final String qrCodeHash;
  final bool alreadyCheckedIn;
}

/// The guest list downloaded for offline door scanning.
class CheckInManifest {
  const CheckInManifest({
    required this.eventId,
    required this.version,
    required this.issuedAt,
    required this.expiresAt,
    required this.downloadedAt,
    required this.attendees,
  });

  final String eventId;
  final int version;
  final DateTime issuedAt;

  /// Freshness contract set by the server. Past this, offline scans are
  /// no longer verified against the list.
  final DateTime expiresAt;
  final DateTime downloadedAt;
  final List<CheckInManifestAttendee> attendees;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}
