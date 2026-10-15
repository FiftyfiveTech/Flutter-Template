import 'check_in_conflict.dart';

class CheckInSyncReport {
  const CheckInSyncReport({
    required this.acceptedCount,
    required this.conflicts,
    required this.remainingCount,
  });

  final int acceptedCount;

  /// Rejections from this sync run (also persisted for the hub).
  final List<CheckInConflict> conflicts;

  /// Still queued because the server couldn't be reached for these.
  final int remainingCount;
}
