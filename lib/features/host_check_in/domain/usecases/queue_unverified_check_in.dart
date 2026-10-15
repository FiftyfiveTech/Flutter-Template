import '../../../../core/error/result.dart';
import '../entities/check_in_outcome.dart';
import '../entities/check_in_result.dart';
import '../repositories/check_in_repository.dart';

/// Lets an offline scan that couldn't be matched to the guest list in the
/// door, queuing the raw QR for the server to verify on sync. The server
/// still decides whether the guest counts as checked in (and so enters
/// matching); a forged ticket comes back as a sync conflict.
class QueueUnverifiedCheckInUseCase {
  const QueueUnverifiedCheckInUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<CheckInResult>> call({
    required String eventId,
    required String qrCode,
    required DateTime now,
  }) async {
    final queued = await _repository.queueCheckIn(
      eventId: eventId,
      method: CheckInMethod.qr,
      scannedAt: now,
      qrCode: qrCode,
    );
    return queued.when(
      ok: (_) => Ok(
        CheckInResult(
          outcome: CheckInOutcome.accepted,
          method: CheckInMethod.qr,
          scannedAt: now,
          isOffline: true,
        ),
      ),
      err: Err.new,
    );
  }
}
