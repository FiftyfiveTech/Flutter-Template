import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/counter_dto.dart';

abstract interface class CounterLocalDatasource {
  Future<CounterDto?> getLocalCount();
  Future<void> saveLocalCount(CounterDto count);
}

class DriftCounterLocalDatasource implements CounterLocalDatasource {
  DriftCounterLocalDatasource(this._db);
  final AppDatabase _db;

  @override
  Future<CounterDto?> getLocalCount() async {
    // Select first or default count row
    final row = await _db.select(_db.counterTable).getSingleOrNull();
    if (row == null) return null;
    
    return CounterDto(
      id: row.id,
      value: row.value,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> saveLocalCount(CounterDto count) async {
    await _db.into(_db.counterTable).insertOnConflictUpdate(
      CounterTableCompanion(
        id: Value(count.id),
        value: Value(count.value),
        updatedAt: Value(count.updatedAt),
        synced: const Value(true),
      ),
    );
  }
}
