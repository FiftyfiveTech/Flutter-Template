import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/check_in_manifest.dart';
import '../entities/check_in_outcome.dart';
import '../entities/check_in_result.dart';
import '../repositories/check_in_repository.dart';
import '../services/qr_hasher.dart';

/// Checks in a scanned ticket: verified by the server when it's reachable,
/// otherwise against the downloaded guest list and queued for sync, so
/// the door never depends on venue wifi.
class CheckInTicketUseCase {
  const CheckInTicketUseCase(this._repository, this._hasher);

  final CheckInRepository _repository;
  final QrHasher _hasher;

  /// [now] is the server-corrected time, used for the manifest's expiry
  /// check and as the offline scan's timestamp.
  Future<Result<CheckInResult>> call({
    required String eventId,
    required String qrCode,
    required DateTime now,
  }) async {
    final code = qrCode.trim();
    if (code.isEmpty) {
      return const Ok(
        CheckInResult(
          outcome: CheckInOutcome.invalidTicket,
          method: CheckInMethod.qr,
        ),
      );
    }

    final online = await _repository.scanOnline(eventId: eventId, qrCode: code);
    switch (online) {
      case Ok(:final value):
        // Keep the offline list in step with what the server decided, so
        // the same ticket is caught if the connection drops next scan.
        if (value.outcome == CheckInOutcome.accepted ||
            value.outcome == CheckInOutcome.alreadyCheckedIn) {
          await _markLocally(eventId, code);
        }
        return online;
      case Err(:final failure) when failure is NetworkFailure:
        return _checkInOffline(eventId: eventId, qrCode: code, now: now);
      case Err():
        return online;
    }
  }

  Future<Result<CheckInResult>> _checkInOffline({
    required String eventId,
    required String qrCode,
    required DateTime now,
  }) async {
    final cached = await _repository.getCachedManifest(eventId);
    final CheckInManifest? manifest;
    switch (cached) {
      case Ok(:final value):
        manifest = value;
      case Err(:final failure):
        return Err(failure);
    }

    CheckInResult unverified(CheckInOutcome outcome) => CheckInResult(
      outcome: outcome,
      method: CheckInMethod.qr,
      isOffline: true,
      qrCode: qrCode,
    );

    if (manifest == null) return Ok(unverified(CheckInOutcome.noGuestList));
    if (manifest.isExpiredAt(now)) {
      return Ok(unverified(CheckInOutcome.guestListExpired));
    }

    final attendee = _find(manifest, qrCode);
    if (attendee == null) return Ok(unverified(CheckInOutcome.notOnGuestList));

    if (attendee.alreadyCheckedIn) {
      return Ok(
        CheckInResult(
          outcome: CheckInOutcome.alreadyCheckedIn,
          method: CheckInMethod.qr,
          attendeeName: attendee.firstName,
          photoUrl: attendee.photoUrl,
          isOffline: true,
        ),
      );
    }

    final queued = await _repository.queueCheckIn(
      eventId: eventId,
      method: CheckInMethod.qr,
      scannedAt: now,
      qrCode: qrCode,
      bookingId: attendee.bookingId,
      attendeeName: attendee.firstName,
    );
    return queued.when(
      ok: (_) => Ok(
        CheckInResult(
          outcome: CheckInOutcome.accepted,
          method: CheckInMethod.qr,
          attendeeName: attendee.firstName,
          photoUrl: attendee.photoUrl,
          scannedAt: now,
          isOffline: true,
        ),
      ),
      err: Err.new,
    );
  }

  Future<void> _markLocally(String eventId, String qrCode) async {
    final cached = await _repository.getCachedManifest(eventId);
    if (cached case Ok(value: final manifest?)) {
      final attendee = _find(manifest, qrCode);
      if (attendee != null && !attendee.alreadyCheckedIn) {
        await _repository.markCheckedInLocally(
          eventId: eventId,
          bookingId: attendee.bookingId,
        );
      }
    }
  }

  CheckInManifestAttendee? _find(CheckInManifest manifest, String qrCode) {
    final hash = _hasher.hash(qrCode).toLowerCase();
    for (final attendee in manifest.attendees) {
      if (attendee.qrCodeHash.toLowerCase() == hash) return attendee;
    }
    return null;
  }
}
