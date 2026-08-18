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
  return BaseApiClient(dio);
}
