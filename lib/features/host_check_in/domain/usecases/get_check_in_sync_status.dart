import '../../../../core/error/result.dart';
import '../entities/check_in_conflict.dart';
import '../entities/check_in_manifest.dart';
import '../entities/check_in_sync_status.dart';
import '../entities/pending_check_in.dart';
import '../repositories/check_in_repository.dart';

class GetCheckInSyncStatusUseCase {
  const GetCheckInSyncStatusUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<CheckInSyncStatus>> call(String eventId) async {
    final pending = await _repository.getPendingCheckIns(eventId);
    final conflicts = await _repository.getConflicts(eventId);
    final manifest = await _repository.getCachedManifest(eventId);
    return switch ((pending, conflicts, manifest)) {
      (Err(:final failure), _, _) => Err(failure),
      (_, Err(:final failure), _) => Err(failure),
      (_, _, Err(:final failure)) => Err(failure),
      (
        Ok<List<PendingCheckIn>>(value: final p),
        Ok<List<CheckInConflict>>(value: final c),
        Ok<CheckInManifest?>(value: final m),
      ) =>
        Ok(CheckInSyncStatus(pending: p, conflicts: c, manifest: m)),
    };
  }
}
