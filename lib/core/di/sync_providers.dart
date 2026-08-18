import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../sync/sync_queue_processor.dart';
import 'database_providers.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
SyncQueueProcessor syncQueueProcessor(Ref ref) {
  return SyncQueueProcessor(
    ref.watch(appDatabaseProvider),
    const [], // Swap-friendly adapters registered here per-feature
  );
}
