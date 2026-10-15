import 'check_in_outcome.dart';

enum CheckInMethod { qr, manual }

/// The outcome of one scan or manual check-in, as shown on the door's
/// result card.
class CheckInResult {
  const CheckInResult({
    required this.outcome,
    required this.method,
    this.attendeeName,
    this.photoUrl,
    this.scannedAt,
    this.isOffline = false,
    this.message,
    this.qrCode,
  });

  final CheckInOutcome outcome;
  final CheckInMethod method;
  final String? attendeeName;
  final String? photoUrl;

  /// When this check-in (or, for [CheckInOutcome.alreadyCheckedIn], the
  /// original one) happened, if known.
  final DateTime? scannedAt;

  /// Decided on-device against the downloaded guest list rather than by
  /// the server. An admitted offline result is queued for sync.
  final bool isOffline;

  /// Server-provided reason, shown for rejections it explains itself.
  final String? message;

  /// The scanned code, kept only so an unverifiable offline scan can be
  /// queued for verification from the result card.
  final String? qrCode;
}
