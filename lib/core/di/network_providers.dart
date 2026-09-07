import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/base_api_client.dart';

part 'network_providers.g.dart';

/// Bearer token attached to every REST request via [baseApiClientProvider]'s interceptor.
///
/// Firebase/Firestore attaches its own auth token automatically through the SDK, but a plain
/// REST/Dio client has no such mechanism — this is the REST-side equivalent. Returns `null` (no
/// `Authorization` header) by default. Once a project adds an auth feature, override this to read
/// the current token from that feature's repository/secure storage — no other file needs to
/// change.
@Riverpod(keepAlive: true)
Future<String?> authToken(Ref ref) async => null;

@Riverpod(keepAlive: true)
BaseApiClient baseApiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com',
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
    ),
  );

  return BaseApiClient(dio);
}
