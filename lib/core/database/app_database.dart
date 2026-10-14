import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/host_onboarding/data/local/host_onboarding_progress_table.dart';
import '../../features/host_profile/data/local/host_profile_table.dart';
import 'host_session_table.dart';
import 'sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SyncQueueEntries,
    HostSessionTable,
    HostOnboardingProgressTable,
    HostProfileTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(hostSessionTable);
        await m.createTable(hostOnboardingProgressTable);
      }
      if (from < 3) {
        await m.addColumn(hostSessionTable, hostSessionTable.businessName);
      }
      if (from < 4) {
        await m.createTable(hostProfileTable);
      }
    },
  );

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
