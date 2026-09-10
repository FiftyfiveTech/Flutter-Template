import 'package:drift/drift.dart';

/// Single-row table (`id` always 0) holding the signed-in host's session,
/// so an app restart doesn't require signing in again mid-onboarding.
class HostSessionTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get accessToken => text()();
  TextColumn get userId => text()();
  TextColumn get accountStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
