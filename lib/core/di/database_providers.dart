import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../session/host_session_local_datasource.dart';

part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
HostSessionLocalDatasource hostSessionLocalDatasource(Ref ref) {
  return DriftHostSessionLocalDatasource(ref.watch(appDatabaseProvider));
}
