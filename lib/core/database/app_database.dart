import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/sample_counter/data/local/counter_table.dart';
import 'sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SyncQueueEntries,
    CounterTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  Future<void> wipeAllTables() async {
    await batch((batch) {
      for (final table in allTables) {
        batch.deleteAll(table);
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'app_template.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
