import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/check_in_attendee.dart';
import '../../domain/entities/check_in_conflict.dart';
import '../../domain/entities/check_in_manifest.dart';
import '../../domain/entities/check_in_outcome.dart';
import '../../domain/entities/check_in_result.dart';
import '../../domain/entities/check_in_sync_report.dart';
import '../../domain/entities/pending_check_in.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../datasources/check_in_local_datasource.dart';
import '../datasources/check_in_remote_datasource.dart';
import '../models/check_in_outcome_mapper.dart';
import '../models/check_in_scan_response_dto.dart';
import '../models/check_in_sync_dto.dart';
import '../services/check_in_id_generator.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  CheckInRepositoryImpl(
    this._remote,
    this._local,
    this._ids, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CheckInRemoteDatasource _remote;
  final CheckInLocalDatasource _local;
  final CheckInIdGenerator _ids;
  final DateTime Function() _now;

  /// Max scans per `checkin/sync` call, keeping one request small enough
  /// to finish on a weak venue connection.
  static const _syncBatchSize = 50;

  Future<String> _deviceId() => _local.deviceId(_ids.next);

  @override
  Future<Result<CheckInResult>> scanOnline({
    required String eventId,
    required String qrCode,
  }) {
    return _decide(
      CheckInMethod.qr,
      () async => _remote.scan(
        eventId: eventId,
        qrCode: qrCode,
        scannerDeviceId: await _deviceId(),
      ),
    );
  }

  @override
  Future<Result<CheckInResult>> manualCheckInOnline({
    required String eventId,
    required String bookingId,
  }) {
    return _decide(
      CheckInMethod.manual,
      () async => _remote.manualCheckIn(
        eventId: eventId,
        bookingId: bookingId,
        scannerDeviceId: await _deviceId(),
      ),
    );
  }

  /// A ticket rejection (4xx carrying a check-in code) is a door decision,
  /// not a failure, so it comes back as `Ok`. Only an unreachable server
  /// is a [NetworkFailure], which triggers the offline fallback.
  Future<Result<CheckInResult>> _decide(
    CheckInMethod method,
    Future<CheckInScanResponseDto> Function() call,
  ) async {
    try {
      final dto = await call();
      return Ok(dto.toDomain(method));
    } on NetworkException catch (e) {
      if (_isUnreachable(e)) return Err(NetworkFailure(message: e.message));
      if (!_isTicketDecision(e)) return Err(ServerFailure(message: e.message));
      return Ok(
        CheckInResult(
          outcome: checkInOutcomeForError(
            code: e.code,
            statusCode: e.statusCode,
          ),
          method: method,
          message: e.message,
        ),
      );
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<List<CheckInAttendee>>> getAttendees(String eventId) async {
    try {
      final dtos = await _remote.getAttendees(eventId);
      return Ok(dtos.map((dto) => dto.toDomain()).toList());
    } on NetworkException catch (e) {
      return Err(_failureFor(e));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<CheckInManifest>> downloadManifest(String eventId) async {
    try {
      final dto = await _remote.getManifest(eventId);
      var manifest = await _local.saveManifest(
        eventId: eventId,
        manifest: dto,
        downloadedAt: _now(),
      );
      // A fresh manifest only knows what the server has synced; re-apply
      // check-ins still queued here so they aren't admitted twice.
      final pendingBookings = {
        for (final p in await _local.pendingFor(eventId))
          if (p.bookingId != null) p.bookingId!,
      };
      if (pendingBookings.isNotEmpty) {
        await _local.markCheckedIn(eventId, pendingBookings);
        manifest = (await _local.loadManifest(eventId))!;
      }
      return Ok(manifest);
    } on NetworkException catch (e) {
      return Err(_failureFor(e));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<CheckInManifest?>> getCachedManifest(String eventId) {
    return _guardLocal(() => _local.loadManifest(eventId));
  }

  @override
  Future<Result<void>> markCheckedInLocally({
    required String eventId,
    required String bookingId,
  }) {
    return _guardLocal(() => _local.markCheckedIn(eventId, {bookingId}));
  }

  @override
  Future<Result<PendingCheckIn>> queueCheckIn({
    required String eventId,
    required CheckInMethod method,
    required DateTime scannedAt,
    String? qrCode,
    String? bookingId,
    String? attendeeName,
  }) {
    return _guardLocal(() async {
      final checkIn = PendingCheckIn(
        scanId: _ids.next(),
        eventId: eventId,
        method: method,
        scannedAt: scannedAt,
        qrCode: qrCode,
        bookingId: bookingId,
        attendeeName: attendeeName,
      );
      await _local.insertPending(checkIn);
      if (bookingId != null) {
        await _local.markCheckedIn(eventId, {bookingId});
      }
      return checkIn;
    });
  }

  @override
  Future<Result<List<PendingCheckIn>>> getPendingCheckIns(String eventId) {
    return _guardLocal(() => _local.pendingFor(eventId));
  }

  @override
  Future<Result<CheckInSyncReport>> syncPendingCheckIns(String eventId) async {
    try {
      final pending = await _local.pendingFor(eventId);
      if (pending.isEmpty) {
        return const Ok(
          CheckInSyncReport(acceptedCount: 0, conflicts: [], remainingCount: 0),
        );
      }
      final deviceId = await _deviceId();
      final run = _SyncRun();

      final scans = [
        for (final p in pending)
          if (p.method == CheckInMethod.qr && p.qrCode != null) p,
      ];
      final manuals = [
        for (final p in pending)
          if (p.method == CheckInMethod.manual && p.bookingId != null) p,
      ];

      for (var i = 0; i < scans.length; i += _syncBatchSize) {
        final batch = scans.skip(i).take(_syncBatchSize).toList();
        if (run.unreachable) {
          run.remaining += batch.length;
          continue;
        }
        await _syncScanBatch(eventId, deviceId, batch, run);
      }
      for (final manual in manuals) {
        if (run.unreachable) {
          run.remaining++;
          continue;
        }
        await _syncManual(eventId, deviceId, manual, run);
      }

      await _local.insertConflicts(run.conflicts);
      await _local.deletePending(run.resolvedScanIds);

      if (run.unreachable && run.accepted == 0 && run.conflicts.isEmpty) {
        return Err(NetworkFailure(message: run.lastError ?? ''));
      }
      return Ok(
        CheckInSyncReport(
          acceptedCount: run.accepted,
          conflicts: run.conflicts,
          remainingCount: run.remaining,
        ),
      );
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<List<String>>> getEventIdsWithPendingCheckIns() {
    return _guardLocal(_local.pendingEventIds);
  }

  Future<void> _syncScanBatch(
    String eventId,
    String deviceId,
    List<PendingCheckIn> batch,
    _SyncRun run,
  ) async {
    try {
      final results = await _remote.sync(
        eventId: eventId,
        scannerDeviceId: deviceId,
        scans: [
          for (final p in batch)
            CheckInSyncScanDto(
              scanId: p.scanId,
              qrCode: p.qrCode!,
              scannedAt: p.scannedAt,
            ),
        ],
      );
      final byScanId = {for (final r in results) r.scanId: r};
      for (final p in batch) {
        final result = byScanId[p.scanId];
        if (result == null) {
          // The server didn't report on this scan; keep it for next time.
          run.remaining++;
          continue;
        }
        final outcome = parseCheckInOutcome(result.outcome);
        // Already checked in by *this* device means an earlier online
        // attempt reached the server even though its response didn't
        // reach us, so this scan isn't a conflict.
        final isOwnEarlierScan =
            outcome == CheckInOutcome.alreadyCheckedIn &&
            result.winningDeviceId == deviceId;
        if (outcome == CheckInOutcome.accepted || isOwnEarlierScan) {
          run.accepted++;
        } else {
          run.conflicts.add(
            CheckInConflict(
              scanId: p.scanId,
              eventId: eventId,
              outcome: outcome,
              scannedAt: p.scannedAt,
              attendeeName: p.attendeeName,
              winningScannedAt: result.winningScannedAt,
              message: result.error,
            ),
          );
        }
        run.resolvedScanIds.add(p.scanId);
      }
    } on NetworkException catch (e) {
      await _local.recordFailedAttempt(batch.map((p) => p.scanId), e.message);
      run.remaining += batch.length;
      run.lastError = e.message;
      if (_isUnreachable(e)) run.unreachable = true;
    }
  }

  Future<void> _syncManual(
    String eventId,
    String deviceId,
    PendingCheckIn manual,
    _SyncRun run,
  ) async {
    CheckInOutcome outcome;
    String? message;
    try {
      final dto = await _remote.manualCheckIn(
        eventId: eventId,
        bookingId: manual.bookingId!,
        scannerDeviceId: deviceId,
      );
      outcome = parseCheckInOutcome(dto.outcome);
    } on NetworkException catch (e) {
      if (_isUnreachable(e) || !_isTicketDecision(e)) {
        await _local.recordFailedAttempt([manual.scanId], e.message);
        run.remaining++;
        run.lastError = e.message;
        if (_isUnreachable(e)) run.unreachable = true;
        return;
      }
      outcome = checkInOutcomeForError(code: e.code, statusCode: e.statusCode);
      message = e.message;
    }
    // The guest list showed them as not checked in when the host tapped,
    // so "already checked in" now means another device got there first.
    // Either way they're in, but it's surfaced so the host knows.
    if (outcome == CheckInOutcome.accepted) {
      run.accepted++;
    } else {
      run.conflicts.add(
        CheckInConflict(
          scanId: manual.scanId,
          eventId: eventId,
          outcome: outcome,
          scannedAt: manual.scannedAt,
          attendeeName: manual.attendeeName,
          message: message,
        ),
      );
    }
    run.resolvedScanIds.add(manual.scanId);
  }

  @override
  Future<Result<List<CheckInConflict>>> getConflicts(String eventId) {
    return _guardLocal(() => _local.conflictsFor(eventId));
  }

  @override
  Future<Result<void>> dismissConflict(String scanId) {
    return _guardLocal(() => _local.deleteConflict(scanId));
  }

  Future<Result<T>> _guardLocal<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  /// No response at all, or the server itself is failing. Either way the
  /// door must keep working offline.
  static bool _isUnreachable(NetworkException e) =>
      e.statusCode == null || e.statusCode! >= 500;

  /// A 4xx about the ticket itself, as opposed to auth (401/403) or rate
  /// limiting (429), which say nothing about whether the guest may enter.
  static bool _isTicketDecision(NetworkException e) {
    final status = e.statusCode;
    return status != null &&
        status >= 400 &&
        status < 500 &&
        status != 401 &&
        status != 403 &&
        status != 429;
  }

  static Failure _failureFor(NetworkException e) => _isUnreachable(e)
      ? NetworkFailure(message: e.message)
      : ServerFailure(message: e.message);
}

class _SyncRun {
  int accepted = 0;
  int remaining = 0;
  bool unreachable = false;
  String? lastError;
  final conflicts = <CheckInConflict>[];
  final resolvedScanIds = <String>[];
}
