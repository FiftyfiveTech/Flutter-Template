import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event.dart';

void main() {
  final start = DateTime(2026, 10, 14, 20);
  final end = DateTime(2026, 10, 14, 23);

  HostEvent event(
    HostEventLifecycleStatus status, {
    DateTime? startAt,
    DateTime? endAt,
  }) =>
      HostEvent.empty.copyWith(status: status, startAt: startAt, endAt: endAt);

  test('a published event has ended once its end time passes', () {
    final e = event(
      HostEventLifecycleStatus.published,
      startAt: start,
      endAt: end,
    );
    expect(e.hasEndedAt(end.subtract(const Duration(minutes: 1))), isFalse);
    expect(e.hasEndedAt(end), isTrue);
  });

  test('without an end time, a published event ends at its start', () {
    final e = event(HostEventLifecycleStatus.published, startAt: start);
    expect(e.hasEndedAt(start), isTrue);
  });

  test('completed has always ended; drafts and cancelled never do', () {
    expect(event(HostEventLifecycleStatus.completed).hasEndedAt(start), isTrue);
    expect(
      event(
        HostEventLifecycleStatus.draft,
        startAt: start,
        endAt: end,
      ).hasEndedAt(end.add(const Duration(days: 1))),
      isFalse,
    );
    expect(
      event(
        HostEventLifecycleStatus.cancelled,
        startAt: start,
        endAt: end,
      ).hasEndedAt(end.add(const Duration(days: 1))),
      isFalse,
    );
  });
}
