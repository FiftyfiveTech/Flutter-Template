import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/time/server_clock.dart';

void main() {
  final deviceNow = DateTime.utc(2026, 10, 14, 12);

  test('uses the device clock until synced', () {
    final clock = ServerClock(deviceNow: () => deviceNow);
    expect(clock.now(), deviceNow);
  });

  test('corrects a device clock that runs behind the server', () {
    final clock = ServerClock(deviceNow: () => deviceNow)
      ..sync(deviceNow.add(const Duration(hours: 2)));
    expect(clock.now(), deviceNow.add(const Duration(hours: 2)));
  });

  test('corrects a device clock that runs ahead of the server', () {
    final clock = ServerClock(deviceNow: () => deviceNow)
      ..sync(deviceNow.subtract(const Duration(minutes: 30)));
    expect(clock.now(), deviceNow.subtract(const Duration(minutes: 30)));
  });
}
