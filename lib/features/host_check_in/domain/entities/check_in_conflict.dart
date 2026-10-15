import 'check_in_outcome.dart';

/// An offline check-in the server rejected on sync, e.g. the same ticket
/// was already scanned on another device. Shown on the hub until the host
/// dismisses it; there is deliberately no override.
class CheckInConflict {
  const CheckInConflict({
    required this.scanId,
    required this.eventId,
    required this.outcome,
    required this.scannedAt,
    this.attendeeName,
    this.winningScannedAt,
    this.message,
  });

  final String scanId;
  final String eventId;
  final CheckInOutcome outcome;
  final DateTime scannedAt;
  final String? attendeeName;

  /// When the check-in that won (on another device) happened.
  final DateTime? winningScannedAt;
  final String? message;
}
