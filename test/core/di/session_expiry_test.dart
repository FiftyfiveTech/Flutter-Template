import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/di/database_providers.dart';
import 'package:host_mobile_app/core/di/network_providers.dart';
import 'package:host_mobile_app/core/di/session_providers.dart';
import 'package:host_mobile_app/core/network/base_api_client.dart';
import 'package:host_mobile_app/core/session/host_session.dart';

import '../../support/fakes.dart';

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode, {this.beforeResponse});

  final int statusCode;

  /// Runs while the request is "in flight", before the response returns.
  final void Function()? beforeResponse;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    beforeResponse?.call();
    return ResponseBody.fromString(
      '{"statusCode": $statusCode, "code": "INVALID_TOKEN", '
      '"message": "Authentication is required."}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _session = HostSession(
  accessToken: 'token-1',
  userId: 'u1',
  accountStatus: 'active',
);

void main() {
  late ProviderContainer container;
  late FakeHostSessionLocalDatasource sessionStore;

  setUp(() {
    sessionStore = FakeHostSessionLocalDatasource();
    container = ProviderContainer(
      overrides: [
        hostSessionLocalDatasourceProvider.overrideWithValue(sessionStore),
      ],
    );
  });

  tearDown(() => container.dispose());

  BaseApiClient clientReturning(
    int statusCode, {
    void Function()? beforeResponse,
  }) {
    final client = container.read(baseApiClientProvider);
    client.dio.httpClientAdapter = _StatusAdapter(
      statusCode,
      beforeResponse: beforeResponse,
    );
    return client;
  }

  Future<void> getIgnoringError(BaseApiClient client) => client
      .get<Object>('/api/v1/host/events')
      .then<void>((_) {}, onError: (_) {});

  test('a 401 on an authenticated request expires the session', () async {
    container.read(hostSessionControllerProvider.notifier).setSession(_session);
    final client = clientReturning(401);

    await getIgnoringError(client);

    expect(container.read(hostSessionControllerProvider), isNull);
    expect(await sessionStore.load(), isNull);
    expect(container.read(sessionExpiryProvider), 1);
  });

  test('parallel 401s only expire the session once', () async {
    container.read(hostSessionControllerProvider.notifier).setSession(_session);
    final client = clientReturning(401);

    await Future.wait([getIgnoringError(client), getIgnoringError(client)]);

    expect(container.read(sessionExpiryProvider), 1);
  });

  test('a 401 for a request sent before a re-login keeps the new '
      'session', () async {
    final notifier = container.read(hostSessionControllerProvider.notifier);
    notifier.setSession(_session);
    const renewed = HostSession(
      accessToken: 'token-2',
      userId: 'u1',
      accountStatus: 'active',
    );
    final client = clientReturning(
      401,
      beforeResponse: () => notifier.setSession(renewed),
    );

    await getIgnoringError(client);

    expect(
      container.read(hostSessionControllerProvider)?.accessToken,
      'token-2',
    );
    expect(container.read(sessionExpiryProvider), 0);
  });

  test('a 401 with no session (e.g. OTP login) does nothing', () async {
    final client = clientReturning(401);

    await getIgnoringError(client);

    expect(container.read(sessionExpiryProvider), 0);
  });

  test('other errors keep the session', () async {
    container.read(hostSessionControllerProvider.notifier).setSession(_session);
    final client = clientReturning(403);

    await getIgnoringError(client);

    expect(container.read(hostSessionControllerProvider), isNotNull);
    expect(container.read(sessionExpiryProvider), 0);
  });
}
