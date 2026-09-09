import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../session/host_session.dart';

part 'session_providers.g.dart';

/// Holds the current [HostSession] in memory. `null` when signed out.
/// [authTokenProvider] reads `accessToken` off this to attach the bearer
/// token to every REST request.
@Riverpod(keepAlive: true)
class HostSessionController extends _$HostSessionController {
  @override
  HostSession? build() => null;

  void setSession(HostSession session) {
    state = session;
  }

  void clear() {
    state = null;
  }
}
