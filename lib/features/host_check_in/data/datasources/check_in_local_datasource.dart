import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/check_in_conflict.dart';
import '../../domain/entities/check_in_manifest.dart';
import '../../domain/entities/check_in_outcome.dart';
import '../../domain/entities/check_in_result.dart';
import '../../domain/entities/pending_check_in.dart';
import '../models/check_in_manifest_dto.dart';

abstract interface class CheckInLocalDatasource {
  Future<CheckInManifest?> loadManifest(String eventId);

  Future<CheckInManifest> saveManifest({
    required String eventId,
    required CheckInManifestDto manifest,
    required DateTime downloadedAt,
  });

  /// Flags [bookingIds] as checked in on the cached manifest (no-op when
  /// there's no cached manifest or none of them are on it).
  Future<void> markCheckedIn(String eventId, Set<String> bookingIds);

  Future<void> insertPending(PendingCheckIn checkIn);

  Future<List<PendingCheckIn>> pendingFor(String eventId);

  Future<List<String>> pendingEventIds();

  Future<void> deletePending(Iterable<String> scanIds);

  Future<void> recordFailedAttempt(Iterable<String> scanIds, String error);

  Future<void> insertConflicts(List<CheckInConflict> conflicts);

  Future<List<CheckInConflict>> conflictsFor(String eventId);

  Future<void> deleteConflict(String scanId);

  /// This install's scanner device id, created on first use.
  Future<String> deviceId(String Function() generate);
}

class DriftCheckInLocalDatasource implements CheckInLocalDatasource {
  DriftCheckInLocalDatasource(this._db);
  final AppDatabase _db;

  @override
  Future<CheckInManifest?> loadManifest(String eventId) async {
    final row = await (_db.select(
      _db.checkInManifestTable,
    )..where((t) => t.eventId.equals(eventId))).getSingleOrNull();
    if (row == null) return null;
    return CheckInManifest(
      eventId: row.eventId,
      version: row.version,
      issuedAt: row.issuedAt,
      expiresAt: row.expiresAt,
      downloadedAt: row.downloadedAt,
      attendees: _decodeAttendees(
        row.attendeesJson,
      ).map((a) => a.toDomain()).toList(),
    );
  }

  @override
  Future<CheckInManifest> saveManifest({
    required String eventId,
    required CheckInManifestDto manifest,
    required DateTime downloadedAt,
  }) async {
    await _db
        .into(_db.checkInManifestTable)
        .insertOnConflictUpdate(
          CheckInManifestTableCompanion.insert(
            eventId: eventId,
            version: manifest.manifestVersion,
            serverSignature: manifest.serverSignature,
            issuedAt: manifest.issuedAt,
            expiresAt: manifest.expiresAt,
            downloadedAt: downloadedAt,
            attendeesJson: _encodeAttendees(manifest.attendees),
          ),
        );
    return (await loadManifest(eventId))!;
  }

  @override
  Future<void> markCheckedIn(String eventId, Set<String> bookingIds) async {
    if (bookingIds.isEmpty) return;
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.checkInManifestTable,
      )..where((t) => t.eventId.equals(eventId))).getSingleOrNull();
      if (row == null) return;
      final current = _decodeAttendees(row.attendeesJson);
      bool needsMark(CheckInManifestAttendeeDto a) =>
          !a.alreadyCheckedIn && bookingIds.contains(a.bookingId);
      if (!current.any(needsMark)) return;
      final attendees = [
        for (final a in current) needsMark(a) ? a.markedCheckedIn() : a,
      ];
      await (_db.update(
        _db.checkInManifestTable,
      )..where((t) => t.eventId.equals(eventId))).write(
        CheckInManifestTableCompanion(
          attendeesJson: Value(_encodeAttendees(attendees)),
        ),
      );
    });
  }

  @override
  Future<void> insertPending(PendingCheckIn checkIn) {
    return _db
        .into(_db.checkInPendingTable)
        .insert(
          CheckInPendingTableCompanion.insert(
            scanId: checkIn.scanId,
            eventId: checkIn.eventId,
            method: checkIn.method.name,
            qrCode: Value(checkIn.qrCode),
            bookingId: Value(checkIn.bookingId),
            attendeeName: Value(checkIn.attendeeName),
            scannedAt: checkIn.scannedAt,
          ),
        );
  }

  @override
  Future<List<PendingCheckIn>> pendingFor(String eventId) async {
    final rows =
        await (_db.select(_db.checkInPendingTable)
              ..where((t) => t.eventId.equals(eventId))
              ..orderBy([(t) => OrderingTerm.asc(t.scannedAt)]))
            .get();
    return [
      for (final row in rows)
        PendingCheckIn(
          scanId: row.scanId,
          eventId: row.eventId,
          method: row.method == CheckInMethod.manual.name
              ? CheckInMethod.manual
              : CheckInMethod.qr,
          scannedAt: row.scannedAt,
          qrCode: row.qrCode,
          bookingId: row.bookingId,
          attendeeName: row.attendeeName,
        ),
    ];
  }

  @override
  Future<List<String>> pendingEventIds() {
    final query = _db.selectOnly(_db.checkInPendingTable, distinct: true)
      ..addColumns([_db.checkInPendingTable.eventId]);
    return query.map((row) => row.read(_db.checkInPendingTable.eventId)!).get();
  }

  @override
  Future<void> deletePending(Iterable<String> scanIds) {
    final ids = scanIds.toList();
    if (ids.isEmpty) return Future.value();
    return (_db.delete(
      _db.checkInPendingTable,
    )..where((t) => t.scanId.isIn(ids))).go();
  }

  @override
  Future<void> recordFailedAttempt(
    Iterable<String> scanIds,
    String error,
  ) async {
    final ids = scanIds.toList();
    if (ids.isEmpty) return;
    await (_db.update(
      _db.checkInPendingTable,
    )..where((t) => t.scanId.isIn(ids))).write(
      CheckInPendingTableCompanion.custom(
        attempts: _db.checkInPendingTable.attempts + const Constant(1),
        lastError: Variable(error),
      ),
    );
  }

  @override
  Future<void> insertConflicts(List<CheckInConflict> conflicts) async {
    if (conflicts.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.checkInConflictTable, [
        for (final c in conflicts)
          CheckInConflictTableCompanion.insert(
            scanId: c.scanId,
            eventId: c.eventId,
            outcome: c.outcome.name,
            attendeeName: Value(c.attendeeName),
            scannedAt: c.scannedAt,
            winningScannedAt: Value(c.winningScannedAt),
            message: Value(c.message),
          ),
      ]);
    });
  }

  @override
  Future<List<CheckInConflict>> conflictsFor(String eventId) async {
    final rows =
        await (_db.select(_db.checkInConflictTable)
              ..where((t) => t.eventId.equals(eventId))
              ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
            .get();
    return [
      for (final row in rows)
        CheckInConflict(
          scanId: row.scanId,
          eventId: row.eventId,
          outcome: CheckInOutcome.values.firstWhere(
            (o) => o.name == row.outcome,
            orElse: () => CheckInOutcome.rejected,
          ),
          scannedAt: row.scannedAt,
          attendeeName: row.attendeeName,
          winningScannedAt: row.winningScannedAt,
          message: row.message,
        ),
    ];
  }

  @override
  Future<void> deleteConflict(String scanId) {
    return (_db.delete(
      _db.checkInConflictTable,
    )..where((t) => t.scanId.equals(scanId))).go();
  }

  @override
  Future<String> deviceId(String Function() generate) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.checkInDeviceTable,
      )..where((t) => t.id.equals(0))).getSingleOrNull();
      if (row != null) return row.deviceId;
      final id = generate();
      await _db
          .into(_db.checkInDeviceTable)
          .insert(
            CheckInDeviceTableCompanion.insert(
              id: const Value(0),
              deviceId: id,
            ),
          );
      return id;
    });
  }

  List<CheckInManifestAttendeeDto> _decodeAttendees(String json) {
    return (jsonDecode(json) as List<dynamic>)
        .map(
          (e) => CheckInManifestAttendeeDto.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  String _encodeAttendees(List<CheckInManifestAttendeeDto> attendees) =>
      jsonEncode(attendees.map((a) => a.toJson()).toList());
}
