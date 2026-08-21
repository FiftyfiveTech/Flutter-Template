import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/base_api_client.dart';

part 'network_providers.g.dart';

@Riverpod(keepAlive: true)
BaseApiClient baseApiClient(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  // Example Bearer Token interceptor:
  // dio.interceptors.add(InterceptorsWrapper(
  //   onRequest: (options, handler) async {
  //     final token = await ref.read(authRepositoryProvider).getToken();
  //     if (token != null) {
  //       options.headers['Authorization'] = 'Bearer $token';
  //     }
  //     return handler.next(options);
  //   },
  // ));

  return BaseApiClient(dio);
}
