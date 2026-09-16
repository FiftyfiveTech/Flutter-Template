import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Logs every REST request/response/error via [debugPrint] — a runnable
/// `curl` command for the request, then status/body for the response or
/// error. The `Authorization` header's value is redacted in the printed
/// curl (the bearer token from [baseApiClient]'s auth interceptor lives
/// there); everything else is printed as sent. Only wired up in debug
/// builds, since request/response bodies can carry PII (business name,
/// phone, email) or the signup access token.
///
/// `adb logcat`/most consoles truncate a single long line (~4KB) — a curl
/// with a JWT plus a couple of upload ids in the body can exceed that, so
/// the console view alone isn't reliable for copy-pasting a full request.
/// Every entry is therefore also appended, untruncated, to a log file (see
/// [logFilePath]) that can be pulled or opened directly when the console
/// view is cut off.
class ApiLoggingInterceptor extends Interceptor {
  File? _logFile;
  bool _printedLogFileLocation = false;

  Future<File> _ensureLogFile() async {
    final existing = _logFile;
    if (existing != null) return existing;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/api_debug.log');
    _logFile = file;
    return file;
  }

  Future<void> _appendToLogFile(String entry) async {
    try {
      final file = await _ensureLogFile();
      if (!_printedLogFileLocation) {
        _printedLogFileLocation = true;
        debugPrint('📄 Full untruncated API log: ${file.path}');
      }
      await file.writeAsString(
        '${DateTime.now().toIso8601String()}\n$entry\n\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Best-effort only — never let logging itself break a request.
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final curl = _toCurl(options);
    debugPrint('→ $curl');
    unawaited(_appendToLogFile('→ $curl'));
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final entry =
        '← ${response.statusCode} ${response.requestOptions.uri}'
        '\n  body: ${response.data}';
    debugPrint(entry);
    unawaited(_appendToLogFile(entry));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final entry =
        '✕ ${err.requestOptions.method} ${err.requestOptions.uri}'
        '\n  status: ${err.response?.statusCode}'
        '\n  body: ${err.response?.data}'
        '\n  error: ${err.message}';
    debugPrint(entry);
    unawaited(_appendToLogFile(entry));
    handler.next(err);
  }

  /// Built as one single-line string, deliberately — logcat/console prefix
  /// every wrapped line with `I/flutter (pid):`, which breaks a multi-line
  /// `\`-continued curl into unselectable fragments. One line stays
  /// copy-pasteable as a whole (console truncation aside — see
  /// [logFilePath] for the untruncated version).
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
