import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/sync_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // If your project uses the Firebase/Firestore backend path (see
  // lib/features/sample_counter/data/datasources/counter_remote_datasource.dart), run
  // `flutterfire configure` and initialize it here before runApp:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Not required for the default REST/Dio path.

  final container = ProviderContainer();
  // Drain any sync-queue entries left over from the last session (Strategy C, outbox sync).
  // Wire this to also run on connectivity-restored/app-resumed events in a real project.
  unawaited(container.read(syncQueueProcessorProvider).processPending());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AppTemplate(),
    ),
  );
}

class AppTemplate extends StatelessWidget {
  const AppTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Template',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
