import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

class NetworkException implements Exception {
  NetworkException(
    this.message, {
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });
  final String message;

  /// HTTP status of the error response; `null` when no response arrived at
  /// all (timeout, no connection) — i.e. the server was never reached.
  final int? statusCode;

  /// The backend envelope's stable machine-readable `code` (e.g.
  /// `MISSING_TOKEN`). Branch on this, never on [message].
  final String? code;

  /// First message per rejected field from a `VALIDATION_FAILED` envelope's
  /// `errors: [{field, errors}]`, keyed by the field's dot-path (e.g.
  /// `firstName`) — lets a form show the server's rule under the right
  /// input. Empty for any other error.
  final Map<String, String> fieldErrors;
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
        headers: {...?headers, ...?options?.headers},
      );
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw _toNetworkException(e);
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
        headers: {...?headers, ...?options?.headers},
      );
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw _toNetworkException(e);
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
        headers: {...?headers, ...?options?.headers},
      );
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    try {
      final requestOptions = (options ?? Options()).copyWith(
        headers: {...?headers, ...?options?.headers},
      );
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw _toNetworkException(e);
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
        headers: {...?headers, ...?options?.headers},
      );
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  NetworkException _toNetworkException(DioException error) {
    final data = error.response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    return NetworkException(
      _handleError(error),
      statusCode: error.response?.statusCode,
      code: code,
      fieldErrors: data is Map ? _fieldErrors(data['errors']) : const {},
    );
  }

  Map<String, String> _fieldErrors(Object? errors) {
    if (errors is! List) return const {};
    final result = <String, String>{};
    for (final entry in errors) {
      if (entry is! Map) continue;
      final field = entry['field']?.toString();
      final inner = entry['errors'];
      if (field == null || inner is! List || inner.isEmpty) continue;
      result.putIfAbsent(field, () => inner.first.toString());
    }
    return result;
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
          final details = _validationDetails(data['errors']);
          if (details != null) return details;
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

  /// Flattens `errors: [{field, errors: [msg, ...]}]` into a readable string,
  /// so a 400 surfaces the specific rule (e.g. "endsAt must not exceed 12
  /// hours after startsAt") instead of the generic "Request validation failed."
  String? _validationDetails(Object? errors) {
    if (errors is! List) return null;
    final messages = <String>[];
    for (final entry in errors) {
      if (entry is Map) {
        final inner = entry['errors'];
        if (inner is List) {
          messages.addAll(inner.map((e) => e.toString()));
        } else if (entry['message'] != null) {
          messages.add(entry['message'].toString());
        }
      } else if (entry != null) {
        messages.add(entry.toString());
      }
    }
    final nonEmpty = messages.where((m) => m.trim().isNotEmpty).toList();
    return nonEmpty.isEmpty ? null : nonEmpty.join('\n');
  }
}
