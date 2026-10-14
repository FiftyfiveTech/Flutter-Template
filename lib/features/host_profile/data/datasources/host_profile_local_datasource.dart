import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/host_profile.dart';

abstract interface class HostProfileLocalDatasource {
  Future<HostProfile?> load();
  Future<void> save(HostProfile profile);
  Future<void> clear();
}

class DriftHostProfileLocalDatasource implements HostProfileLocalDatasource {
  DriftHostProfileLocalDatasource(this._db);
  final AppDatabase _db;

  @override
  Future<HostProfile?> load() async {
    final row = await (_db.select(
      _db.hostProfileTable,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row == null) return null;
    return HostProfile(
      userId: row.userId,
      hostName: row.hostName,
      isVerified: row.isVerified,
      savedVenuesCount: row.savedVenuesCount,
      photoPath: row.photoPath,
    );
  }

  @override
  Future<void> save(HostProfile profile) {
    return _db
        .into(_db.hostProfileTable)
        .insertOnConflictUpdate(
          HostProfileTableCompanion.insert(
            id: const Value(0),
            userId: profile.userId,
            hostName: Value(profile.hostName),
            isVerified: Value(profile.isVerified),
            savedVenuesCount: Value(profile.savedVenuesCount),
            photoPath: Value(profile.photoPath),
          ),
        );
  }

  @override
  Future<void> clear() {
    return (_db.delete(
      _db.hostProfileTable,
    )..where((t) => t.id.equals(0))).go();
  }
}
