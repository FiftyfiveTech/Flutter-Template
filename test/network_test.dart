import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app_template/core/di/network_providers.dart';

/// Captures the [RequestOptions] Dio would have sent, without making a real network call.
class _CapturingHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? capturedOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedOptions = options;
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('baseApiClient auth interceptor', () {
    test('attaches an Authorization header when authTokenProvider returns a token', () async {
      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith((ref) async => 'fake-token'),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(baseApiClientProvider);
      final adapter = _CapturingHttpClientAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.get<Map<String, dynamic>>('/counter');

      expect(adapter.capturedOptions?.headers['Authorization'], 'Bearer fake-token');
    });

    test('sends no Authorization header when authTokenProvider returns null', () async {
      final container = ProviderContainer(
        overrides: [
          authTokenProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(baseApiClientProvider);
      final adapter = _CapturingHttpClientAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.get<Map<String, dynamic>>('/counter');

      expect(adapter.capturedOptions?.headers.containsKey('Authorization'), isFalse);
    });
  });
}
