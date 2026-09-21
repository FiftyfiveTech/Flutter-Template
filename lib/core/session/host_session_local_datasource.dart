import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'host_session.dart';

abstract interface class HostSessionLocalDatasource {
  Future<HostSession?> load();
  Future<void> save(HostSession session);
  Future<void> clear();
}

class DriftHostSessionLocalDatasource implements HostSessionLocalDatasource {
  DriftHostSessionLocalDatasource(this._db);
  final AppDatabase _db;

  @override
  Future<HostSession?> load() async {
    final row = await (_db.select(
      _db.hostSessionTable,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row == null) return null;
    return HostSession(
      accessToken: row.accessToken,
      userId: row.userId,
      accountStatus: row.accountStatus,
      businessName: row.businessName,
    );
  }

  @override
  Future<void> save(HostSession session) {
    return _db
        .into(_db.hostSessionTable)
        .insertOnConflictUpdate(
          HostSessionTableCompanion.insert(
            id: const Value(0),
            accessToken: session.accessToken,
            userId: session.userId,
            accountStatus: session.accountStatus,
            businessName: Value(session.businessName),
          ),
        );
  }

  @override
  Future<void> clear() {
    return (_db.delete(
      _db.hostSessionTable,
    )..where((t) => t.id.equals(0))).go();
  }
}
