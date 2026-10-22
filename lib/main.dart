import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/session_providers.dart';
import 'core/di/theme_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/ah_message_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // If your project uses the Firebase/Firestore backend path, run `flutterfire configure`
  // and initialize it here before runApp:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Not required for the default REST/Dio path.

  // Nothing here drains the sync queue (Strategy C, outbox sync) — that module stays zero-cost
  // for projects using the default Strategy A. See core/di/sync_providers.dart for where to wire
  // it in once a feature actually opts into Strategy C.

  // Restore the host's Appearance choice before the first frame, so a
  // dark-mode host doesn't see the light theme flash on launch.
  final container = ProviderContainer();
  await container.read(themeModeControllerProvider.notifier).hydrate();

  runApp(
    UncontrolledProviderScope(container: container, child: const AppTemplate()),
  );
}

class AppTemplate extends ConsumerWidget {
  const AppTemplate({super.key});

  /// The server rejected the session token (see the 401 handling in
  /// `baseApiClientProvider`) — drop the whole stack and land on login.
  void _onSessionExpired() {
    appRouter.go('/auth/phone');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = appRouter.routerDelegate.navigatorKey.currentContext;
      if (context == null) return;
      showAhMessageSheet(
        context,
        title: 'Session expired',
        message: 'Please log in again to continue.',
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionExpiryProvider, (_, _) => _onSessionExpired());
    final buttonFill = ref.watch(buttonFillControllerProvider);

    return MaterialApp.router(
      title: 'Flutter Template',
      theme: AppTheme.lightWith(buttonFill),
      darkTheme: AppTheme.darkWith(buttonFill),
      themeMode: ref.watch(themeModeControllerProvider),
      routerConfig: appRouter,
    );
  }
}
