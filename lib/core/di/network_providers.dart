import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/api_logging_interceptor.dart';
import '../network/base_api_client.dart';
import '../time/server_clock.dart';
import 'session_providers.dart';

part 'network_providers.g.dart';

/// Bearer token attached to every REST request via [baseApiClientProvider]'s interceptor.
///
/// Firebase/Firestore attaches its own auth token automatically through the SDK, but a plain
/// REST/Dio client has no such mechanism — this is the REST-side equivalent. Reads off
/// [HostSessionController], which H-01 · Signup populates on a successful signup response.
@Riverpod(keepAlive: true)
Future<String?> authToken(Ref ref) async =>
    ref.watch(hostSessionControllerProvider)?.accessToken;

@Riverpod(keepAlive: true)
BaseApiClient baseApiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://desmond-smorzando-untamely.ngrok-free.dev',
      // 'https://jump-untrue-starboard.ngrok-free.dev',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(authTokenProvider.future);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // A 401 means the server rejected our token (expired/revoked/
        // INVALID_TOKEN) — force a fresh login. Only when the request
        // carried the *current* token: a token-less call (OTP login) or a
        // stale in-flight request from before a re-login mustn't sign out
        // the new session.
        final sentAuth = error.requestOptions.headers['Authorization'];
        final current = ref.read(hostSessionControllerProvider)?.accessToken;
        if (error.response?.statusCode == 401 &&
            current != null &&
            sentAuth == 'Bearer $current') {
          ref.read(hostSessionControllerProvider.notifier).expire();
        }
        handler.next(error);
      },
    ),
  );

  dio.interceptors.add(ref.read(serverClockProvider).interceptor);

  if (kDebugMode) {
    dio.interceptors.add(ApiLoggingInterceptor());
  }

  return BaseApiClient(dio);
}
