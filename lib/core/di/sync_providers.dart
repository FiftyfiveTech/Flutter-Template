import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../sync/sync_queue_processor.dart';
import 'database_providers.dart';

part 'sync_providers.g.dart';

/// Only relevant if a feature opts into Strategy C (outbox sync) — see `docs/architecture.md` §5
/// for what that means. This provider itself has no cost if nothing ever enqueues a
/// [SyncQueueEntry]: nothing in `main.dart` calls [processPending] automatically, so projects
/// using the default Strategy A pay nothing for this module.
///
/// Once a feature does use Strategy C, wire draining the queue into your app, e.g. in `main.dart`:
/// ```dart
/// final container = ProviderContainer();
/// unawaited(container.read(syncQueueProcessorProvider).processPending());
/// runApp(UncontrolledProviderScope(container: container, child: const AppTemplate()));
/// ```
/// and/or trigger it again on connectivity-restored/app-resumed events — a single run at cold
/// start won't retry queued writes that failed while the app stays open.
@Riverpod(keepAlive: true)
SyncQueueProcessor syncQueueProcessor(Ref ref) {
  return SyncQueueProcessor(
    ref.watch(appDatabaseProvider),
    const [], // Swap-friendly adapters registered here per-feature
  );
}
