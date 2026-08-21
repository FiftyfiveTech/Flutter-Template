import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // If your project uses the Firebase/Firestore backend path (see
  // lib/features/sample_counter/data/datasources/counter_remote_datasource.dart), run
  // `flutterfire configure` and initialize it here before runApp:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Not required for the default REST/Dio path.

  // Nothing here drains the sync queue (Strategy C, outbox sync) — that module stays zero-cost
  // for projects using the default Strategy A. See core/di/sync_providers.dart for where to wire
  // it in once a feature actually opts into Strategy C.

  runApp(
    const ProviderScope(
      child: AppTemplate(),
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
