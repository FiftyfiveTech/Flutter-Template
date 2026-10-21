import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/session_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/ah_message_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // If your project uses the Firebase/Firestore backend path, run `flutterfire configure`
  // and initialize it here before runApp:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Not required for the default REST/Dio path.

  // Nothing here drains the sync queue (Strategy C, outbox sync) — that module stays zero-cost
  // for projects using the default Strategy A. See core/di/sync_providers.dart for where to wire
  // it in once a feature actually opts into Strategy C.

  runApp(const ProviderScope(child: AppTemplate()));
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

    return MaterialApp.router(
      title: 'Flutter Template',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
