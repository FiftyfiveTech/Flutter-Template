import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/check_in_attendee.dart';
import '../entities/guest_list.dart';
import '../entities/pending_check_in.dart';
import '../repositories/check_in_repository.dart';

/// The door's guest list: live from the server when reachable, otherwise
/// rebuilt from the downloaded manifest. Either way, check-ins still
/// queued on this device are overlaid as checked in (pending sync).
class GetGuestListUseCase {
  const GetGuestListUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<GuestList>> call(String eventId) async {
    final pendingResult = await _repository.getPendingCheckIns(eventId);
    final pending = pendingResult.when(
      ok: (value) => value,
      err: (_) => const <PendingCheckIn>[],
    );

    final online = await _repository.getAttendees(eventId);
    switch (online) {
      case Ok(:final value):
        return Ok(
          GuestList(attendees: _overlay(value, pending), isOffline: false),
        );
      case Err(:final failure) when failure is NetworkFailure:
        final cached = await _repository.getCachedManifest(eventId);
        if (cached case Ok(value: final manifest?)) {
          final attendees = [
            for (final a in manifest.attendees)
              CheckInAttendee(
                bookingId: a.bookingId,
                userId: a.userId,
                firstName: a.firstName,
                photoUrl: a.photoUrl,
                checkedIn: a.alreadyCheckedIn,
              ),
          ];
          return Ok(
            GuestList(attendees: _overlay(attendees, pending), isOffline: true),
          );
        }
        return Err(failure);
      case Err(:final failure):
        return Err(failure);
    }
  }

  List<CheckInAttendee> _overlay(
    List<CheckInAttendee> attendees,
    List<PendingCheckIn> pending,
  ) {
    final pendingByBooking = {
      for (final p in pending)
        if (p.bookingId != null) p.bookingId!: p,
    };
    return [
      for (final a in attendees)
        if (!a.checkedIn && pendingByBooking.containsKey(a.bookingId))
          a.copyWith(
            checkedIn: true,
            scannedAt: pendingByBooking[a.bookingId]!.scannedAt,
            isPendingSync: true,
          )
        else
          a,
    ];
  }
}
