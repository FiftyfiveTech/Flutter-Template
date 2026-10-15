import 'package:drift/drift.dart';

/// The last downloaded offline guest list per event. Attendees are kept as
/// a JSON array; it's only ever read and rewritten whole, and holds QR
/// hashes, never the codes themselves.
class CheckInManifestTable extends Table {
  TextColumn get eventId => text()();
  IntColumn get version => integer()();
  TextColumn get serverSignature => text()();
  DateTimeColumn get issuedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get downloadedAt => dateTime()();
  TextColumn get attendeesJson => text()();

  @override
  Set<Column> get primaryKey => {eventId};
}

/// Outbox of check-ins made while the server was unreachable.
///
/// Feature-local rather than the generic `SyncQueueEntries`: QR scans sync
/// as one batch call with a per-scan result (accepted vs. conflict), which
/// the one-entry-at-a-time `SyncQueueAdapter.push` contract can't express.
/// A row is deleted once the server has decided it either way.
class CheckInPendingTable extends Table {
  TextColumn get scanId => text()();
  TextColumn get eventId => text()();

  /// `qr` or `manual`.
  TextColumn get method => text()();
  TextColumn get qrCode => text().nullable()();
  TextColumn get bookingId => text().nullable()();
  TextColumn get attendeeName => text().nullable()();
  DateTimeColumn get scannedAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {scanId};
}

/// Offline check-ins the server rejected on sync, kept until the host
/// dismisses them on the check-in hub.
class CheckInConflictTable extends Table {
  TextColumn get scanId => text()();
  TextColumn get eventId => text()();
  TextColumn get outcome => text()();
  TextColumn get attendeeName => text().nullable()();
  DateTimeColumn get scannedAt => dateTime()();
  DateTimeColumn get winningScannedAt => dateTime().nullable()();
  TextColumn get message => text().nullable()();

  @override
  Set<Column> get primaryKey => {scanId};
}

/// Single row (`id` always 0): this install's stable scanner device id,
/// sent as `scannerDeviceId` so the server can attribute scans and tell
/// this device's own earlier check-in apart from another device's.
class CheckInDeviceTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}
