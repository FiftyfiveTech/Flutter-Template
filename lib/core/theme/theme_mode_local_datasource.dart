import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';

abstract interface class ThemeModeLocalDatasource {
  /// The saved Appearance choice, or `null` if the host never changed it.
  Future<ThemeMode?> load();
  Future<void> save(ThemeMode mode);
}

class DriftThemeModeLocalDatasource implements ThemeModeLocalDatasource {
  DriftThemeModeLocalDatasource(this._db);
  final AppDatabase _db;

  @override
  Future<ThemeMode?> load() async {
    final row = await (_db.select(
      _db.appPreferencesTable,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row == null) return null;
    return ThemeMode.values.asNameMap()[row.themeMode];
  }

  @override
  Future<void> save(ThemeMode mode) {
    return _db
        .into(_db.appPreferencesTable)
        .insertOnConflictUpdate(
          AppPreferencesTableCompanion.insert(
            id: const Value(0),
            themeMode: Value(mode.name),
          ),
        );
  }
}
