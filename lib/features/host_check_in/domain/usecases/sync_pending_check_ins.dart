import '../../../../core/error/result.dart';
import '../entities/check_in_sync_report.dart';
import '../repositories/check_in_repository.dart';

/// Pushes offline check-ins to the server. Ones it rejects become
/// conflicts; ones it can't reach stay queued for the next attempt.
class SyncPendingCheckInsUseCase {
  const SyncPendingCheckInsUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<CheckInSyncReport>> call(String eventId) =>
      _repository.syncPendingCheckIns(eventId);
}
