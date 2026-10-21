import 'package:drift/drift.dart';

/// Single-row table (`id` always 0) holding device-level app preferences
/// that outlive a session — signing out doesn't reset them.
class AppPreferencesTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  /// The host's Appearance choice: `light`, `dark` or `system` (the
  /// `ThemeMode` enum name).
  TextColumn get themeMode => text().withDefault(const Constant('light'))();

  @override
  Set<Column> get primaryKey => {id};
}
