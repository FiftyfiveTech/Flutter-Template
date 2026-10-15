import '../../../../core/error/result.dart';
import '../entities/check_in_attendee.dart';
import '../entities/check_in_conflict.dart';
import '../entities/check_in_manifest.dart';
import '../entities/check_in_result.dart';
import '../entities/check_in_sync_report.dart';
import '../entities/pending_check_in.dart';

/// Door check-in for one event.
///
/// The online calls return `Ok` for every ticket decision, including
/// rejections like an already-used ticket, and `Err(NetworkFailure)` only
/// when the server couldn't be reached. That failure is the caller's cue
/// to fall back to the offline manifest.
abstract class CheckInRepository {
  Future<Result<CheckInResult>> scanOnline({
    required String eventId,
    required String qrCode,
  });

  Future<Result<CheckInResult>> manualCheckInOnline({
    required String eventId,
    required String bookingId,
  });

  Future<Result<List<CheckInAttendee>>> getAttendees(String eventId);

  /// Downloads and caches the signed manifest, re-applying any still-queued
  /// local check-ins so they don't read as "not checked in" again.
  Future<Result<CheckInManifest>> downloadManifest(String eventId);

  Future<Result<CheckInManifest?>> getCachedManifest(String eventId);

  /// Marks a guest checked in on the cached manifest, so a second scan of
  /// the same ticket offline is caught as already used.
  Future<Result<void>> markCheckedInLocally({
    required String eventId,
    required String bookingId,
  });

  /// Adds an offline check-in to the outbox (and marks it on the cached
  /// manifest when [bookingId] is known).
  Future<Result<PendingCheckIn>> queueCheckIn({
    required String eventId,
    required CheckInMethod method,
    required DateTime scannedAt,
    String? qrCode,
    String? bookingId,
    String? attendeeName,
  });

  Future<Result<List<PendingCheckIn>>> getPendingCheckIns(String eventId);

  Future<Result<CheckInSyncReport>> syncPendingCheckIns(String eventId);

  /// Events with check-ins still queued on this device.
  Future<Result<List<String>>> getEventIdsWithPendingCheckIns();

  Future<Result<List<CheckInConflict>>> getConflicts(String eventId);

  Future<Result<void>> dismissConflict(String scanId);
}
