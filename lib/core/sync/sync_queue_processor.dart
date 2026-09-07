import 'package:drift/drift.dart';

import '../database/app_database.dart';

abstract interface class SyncQueueAdapter {
  String get entityType;
  Future<void> push(SyncQueueEntry entry);
}

class SyncQueueProcessor {
  SyncQueueProcessor(this._db, this._adapters);

  final AppDatabase _db;
  final List<SyncQueueAdapter> _adapters;

  Future<void> processPending() async {
    final pending = await _db.select(_db.syncQueueEntries).get();
    for (final entry in pending) {
      try {
        final adapter = _adapters.firstWhere(
          (a) => a.entityType == entry.entityType,
          orElse: () => throw StateError(
            'No adapter found for entity type: ${entry.entityType}',
          ),
        );

        await adapter.push(entry);

        // Remove from queue on success
        await (_db.delete(
          _db.syncQueueEntries,
        )..where((t) => t.id.equals(entry.id))).go();
      } catch (error) {
        // Increment attempts and update last error on failure
        await (_db.update(
          _db.syncQueueEntries,
        )..where((t) => t.id.equals(entry.id))).write(
          SyncQueueEntriesCompanion(
            attempts: Value(entry.attempts + 1),
            lastError: Value(error.toString()),
          ),
        );
      }
    }
  }
}
