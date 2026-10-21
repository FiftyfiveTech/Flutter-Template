import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/network/base_api_client.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, this.statusCode);

  final String body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<NetworkException> _errorFor(String body, int statusCode) async {
  final dio = Dio()..httpClientAdapter = _StubAdapter(body, statusCode);
  try {
    await BaseApiClient(dio).patch('/api/v1/host/profile', data: {});
  } on NetworkException catch (e) {
    return e;
  }
  fail('expected a NetworkException');
}

void main() {
  test('parses VALIDATION_FAILED errors into per-field messages', () async {
    final e = await _errorFor('''
      {
        "success": false,
        "statusCode": 400,
        "code": "VALIDATION_FAILED",
        "message": "Request validation failed.",
        "error": "BAD_REQUEST",
        "errors": [
          {"field": "firstName", "errors": ["firstName too long", "second"]},
          {"field": "businessName", "errors": ["businessName empty"]}
        ],
        "meta": {}
      }
      ''', 400);

    expect(e.statusCode, 400);
    expect(e.code, 'VALIDATION_FAILED');
    expect(e.fieldErrors, {
      'firstName': 'firstName too long',
      'businessName': 'businessName empty',
    });
  });

  test('has no field errors for a non-validation error', () async {
    final e = await _errorFor(
      '{"statusCode": 403, "code": "FORBIDDEN", "message": "Nope"}',
      403,
    );

    expect(e.message, 'Nope');
    expect(e.fieldErrors, isEmpty);
  });
}
