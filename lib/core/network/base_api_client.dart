import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
}

class BaseApiClient {
  BaseApiClient(this._dio);
  final Dio _dio;

  /// Exposed for tests that need to swap [Dio.httpClientAdapter] to assert on outgoing
  /// requests (e.g. interceptor behavior) without making a real network call.
  @visibleForTesting
  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    try {
      final requestOptions = (options ?? Options()).copyWith(
        headers: {
          ...?headers,
          ...?options?.headers,
        },
      );
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw NetworkException(_handleError(e));
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    try {
      final requestOptions = (options ?? Options()).copyWith(
        headers: {
          ...?headers,
          ...?options?.headers,
        },
      );
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw NetworkException(_handleError(e));
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    try {
      final requestOptions = (options ?? Options()).copyWith(
        headers: {
          ...?headers,
          ...?options?.headers,
        },
      );
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw NetworkException(_handleError(e));
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    try {
      final requestOptions = (options ?? Options()).copyWith(
        headers: {
          ...?headers,
          ...?options?.headers,
        },
      );
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw NetworkException(_handleError(e));
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out';
      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null && response.data is Map) {
          final data = response.data as Map;
          final serverMsg = data['message'] ?? data['error'] ?? data['msg'];
          if (serverMsg != null) return serverMsg.toString();
        }
        final status = response?.statusCode;
        return 'Server returned status code $status';
      case DioExceptionType.connectionError:
        return 'Failed to connect to host';
      default:
        return 'Network connection issue';
    }
  }
}
