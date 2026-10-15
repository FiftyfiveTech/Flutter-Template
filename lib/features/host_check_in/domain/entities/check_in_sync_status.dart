import 'check_in_conflict.dart';
import 'check_in_manifest.dart';
import 'pending_check_in.dart';

/// Local-only snapshot of the door's offline state for one event.
class CheckInSyncStatus {
  const CheckInSyncStatus({
    required this.pending,
    required this.conflicts,
    this.manifest,
  });

  final List<PendingCheckIn> pending;
  final List<CheckInConflict> conflicts;
  final CheckInManifest? manifest;
}
