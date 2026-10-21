import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../session/host_session.dart';
import 'database_providers.dart';

part 'session_providers.g.dart';

/// Holds the current [HostSession] in memory, backed by
/// `HostSessionLocalDatasource` so an app restart doesn't require
/// signing in again mid-onboarding — see [hydrate]. `null` when signed
/// out. [authTokenProvider] reads `accessToken` off this to attach the
/// bearer token to every REST request.
@Riverpod(keepAlive: true)
class HostSessionController extends _$HostSessionController {
  @override
  HostSession? build() => null;

  /// Loads the persisted session, if any. Called once at app bootstrap
  /// (`HostBootstrapPage`), before the initial route is decided.
  Future<void> hydrate() async {
    final session = await ref.read(hostSessionLocalDatasourceProvider).load();
    if (session != null) state = session;
  }

  void setSession(HostSession session) {
    state = session;
    unawaited(ref.read(hostSessionLocalDatasourceProvider).save(session));
  }

  void clear() {
    state = null;
    unawaited(ref.read(hostSessionLocalDatasourceProvider).clear());
  }

  /// Ends a session the server no longer accepts (a 401 on an
  /// authenticated request) and notifies [sessionExpiryProvider] so the
  /// app routes to login. A no-op when already signed out, so a burst of
  /// parallel 401s only signs out once.
  void expire() {
    if (state == null) return;
    clear();
    ref.read(sessionExpiryProvider.notifier).signal();
  }
}

/// Bumped each time [HostSessionController.expire] ends a session —
/// listened to at the app root to force the user back to login. A
/// counter (not a bool) so every expiry is a distinct change.
@Riverpod(keepAlive: true)
class SessionExpiry extends _$SessionExpiry {
  @override
  int build() => 0;

  void signal() => state++;
}
