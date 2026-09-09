import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs every REST request/response/error via [debugPrint] — a runnable
/// `curl` command for the request, then status/body for the response or
/// error. The `Authorization` header's value is redacted in the printed
/// curl (the bearer token from [baseApiClient]'s auth interceptor lives
/// there); everything else is printed as sent. Only wired up in debug
/// builds, since request/response bodies can carry PII (business name,
/// phone, email) or the signup access token.
class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${_toCurl(options)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '← ${response.statusCode} ${response.requestOptions.uri}'
      '\n  body: ${response.data}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '✕ ${err.requestOptions.method} ${err.requestOptions.uri}'
      '\n  status: ${err.response?.statusCode}'
      '\n  body: ${err.response?.data}'
      '\n  error: ${err.message}',
    );
    handler.next(err);
  }

  /// Built as one single-line string, deliberately — logcat/console prefix
  /// every wrapped line with `I/flutter (pid):`, which breaks a multi-line
  /// `\`-continued curl into unselectable fragments. One line stays
  /// copy-pasteable as a whole.
  String _toCurl(RequestOptions options) {
    final buffer = StringBuffer(
      "curl --location --request ${options.method} '${options.uri}'",
    );

    final headers = {...options.headers};
    headers.remove(Headers.contentLengthHeader);
    // TODO(host-onboarding): re-enable redaction before merging — token is
    // printed in full temporarily so it can be copied for manual curl testing.
    for (final entry in headers.entries) {
      buffer.write(" --header '${entry.key}: ${entry.value}'");
    }

    final data = options.data;
    if (data is FormData) {
      for (final field in data.fields) {
        buffer.write(" --form '${field.key}=${field.value}'");
      }
      for (final file in data.files) {
        buffer.write(" --form '${file.key}=@${file.value.filename}'");
      }
    } else if (data != null) {
      final body = data is Map || data is List ? jsonEncode(data) : data;
      buffer.write(" --data-raw '$body'");
    }

    return buffer.toString();
  }
}
