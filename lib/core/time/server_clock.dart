import 'dart:io' show HttpDate, HttpException;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_clock.g.dart';

/// "Now" according to the backend rather than the device. The offset is
/// learned from the `Date` header of every API response, so a phone with
/// a wrong clock still agrees with the server on whether an event has
/// started or ended. Falls back to the device clock until the first
/// response arrives (e.g. fully offline).
class ServerClock {
  ServerClock({DateTime Function()? deviceNow})
    : _deviceNow = deviceNow ?? DateTime.now;

  final DateTime Function() _deviceNow;
  Duration _offset = Duration.zero;

  /// Server-corrected current time, in the device's local zone.
  DateTime now() => _deviceNow().add(_offset);

  /// Records the server's time as reported at roughly the device's "now".
  void sync(DateTime serverTime) {
    _offset = serverTime.toUtc().difference(_deviceNow().toUtc());
  }

  /// Interceptor that feeds every response's `Date` header into [sync].
  /// An absent or malformed header is ignored, keeping the last offset.
  Interceptor get interceptor => InterceptorsWrapper(
    onResponse: (response, handler) {
      _syncFrom(response.headers.value('date'));
      handler.next(response);
    },
    onError: (error, handler) {
      // Error responses (4xx/5xx) still carry a valid server Date.
      _syncFrom(error.response?.headers.value('date'));
      handler.next(error);
    },
  );

  void _syncFrom(String? header) {
    if (header == null) return;
    try {
      sync(HttpDate.parse(header));
    } on FormatException {
      // Keep the previous offset.
    } on HttpException {
      // Keep the previous offset.
    }
  }
}

@Riverpod(keepAlive: true)
ServerClock serverClock(Ref ref) => ServerClock();
