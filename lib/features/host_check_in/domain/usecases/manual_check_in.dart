import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/check_in_attendee.dart';
import '../entities/check_in_outcome.dart';
import '../entities/check_in_result.dart';
import '../repositories/check_in_repository.dart';

/// Name-search fallback when a guest's QR won't scan. Goes to the server
/// when reachable; offline it's queued and replayed on reconnect.
class ManualCheckInUseCase {
  const ManualCheckInUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<CheckInResult>> call({
    required String eventId,
    required CheckInAttendee attendee,
    required DateTime now,
  }) async {
    if (attendee.checkedIn) {
      return Ok(
        CheckInResult(
          outcome: CheckInOutcome.alreadyCheckedIn,
          method: CheckInMethod.manual,
          attendeeName: attendee.firstName,
          photoUrl: attendee.photoUrl,
          scannedAt: attendee.scannedAt,
          isOffline: attendee.isPendingSync,
        ),
      );
    }

    final online = await _repository.manualCheckInOnline(
      eventId: eventId,
      bookingId: attendee.bookingId,
    );
    switch (online) {
      case Ok(:final value):
        if (value.outcome == CheckInOutcome.accepted ||
            value.outcome == CheckInOutcome.alreadyCheckedIn) {
          await _repository.markCheckedInLocally(
            eventId: eventId,
            bookingId: attendee.bookingId,
          );
        }
        return online;
      case Err(:final failure) when failure is NetworkFailure:
        final queued = await _repository.queueCheckIn(
          eventId: eventId,
          method: CheckInMethod.manual,
          scannedAt: now,
          bookingId: attendee.bookingId,
          attendeeName: attendee.firstName,
        );
        return queued.when(
          ok: (_) => Ok(
            CheckInResult(
              outcome: CheckInOutcome.accepted,
              method: CheckInMethod.manual,
              attendeeName: attendee.firstName,
              photoUrl: attendee.photoUrl,
              scannedAt: now,
              isOffline: true,
            ),
          ),
          err: Err.new,
        );
      case Err():
        return online;
    }
  }
}
