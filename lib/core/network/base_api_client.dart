import 'package:dio/dio.dart';

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
}

class BaseApiClient {
  BaseApiClient(this._dio);
  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw NetworkException(_handleError(e));
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw NetworkException(_handleError(e));
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw NetworkException(_handleError(e));
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data, queryParameters: queryParameters);
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
        final status = error.response?.statusCode;
        return 'Server returned status code $status';
      case DioExceptionType.connectionError:
        return 'Failed to connect to host';
      default:
        return 'Network connection issue';
    }
  }
}
