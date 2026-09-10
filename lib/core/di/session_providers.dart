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
}
