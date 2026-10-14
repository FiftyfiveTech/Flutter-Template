import 'package:drift/drift.dart';

/// Single-row table (`id` always 0) caching the signed-in host's profile
/// so the You tab renders offline. `userId` guards against showing one
/// host's cached profile to another host who signs in on the same device.
///
/// `photoPath` is the host's own chosen avatar copied into private app
/// storage — not an identity document, so it falls outside the "raw ID
/// images are never persisted" rule.
class HostProfileTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get userId => text()();
  TextColumn get hostName => text().withDefault(const Constant(''))();
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  IntColumn get savedVenuesCount => integer().withDefault(const Constant(0))();
  TextColumn get photoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
