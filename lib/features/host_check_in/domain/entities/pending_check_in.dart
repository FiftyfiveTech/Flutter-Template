import 'check_in_result.dart';

/// A check-in made offline, waiting in the local outbox for sync.
/// QR check-ins carry [qrCode] (re-verified by the server on sync);
/// manual ones carry [bookingId].
class PendingCheckIn {
  const PendingCheckIn({
    required this.scanId,
    required this.eventId,
    required this.method,
    required this.scannedAt,
    this.qrCode,
    this.bookingId,
    this.attendeeName,
  });

  final String scanId;
  final String eventId;
  final CheckInMethod method;
  final DateTime scannedAt;
  final String? qrCode;

  /// Known when the scan matched the manifest, or for a manual check-in;
  /// `null` for an unverified QR queued for the server to resolve.
  final String? bookingId;
  final String? attendeeName;
}
