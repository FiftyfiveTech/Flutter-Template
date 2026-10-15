import '../../../../core/error/result.dart';
import '../repositories/check_in_repository.dart';

/// Pushes every event's queued offline check-ins. Door check-in closes
/// when an event ends, so this is how scans still queued at that point
/// reach the server (and so count towards that event's matching).
class SyncAllPendingCheckInsUseCase {
  const SyncAllPendingCheckInsUseCase(this._repository);

  final CheckInRepository _repository;

  Future<void> call() async {
    final eventIds = await _repository.getEventIdsWithPendingCheckIns();
    if (eventIds case Ok(value: final ids)) {
      for (final id in ids) {
        await _repository.syncPendingCheckIns(id);
      }
    }
  }
}
