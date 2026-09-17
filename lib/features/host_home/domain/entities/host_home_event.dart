enum HostEventStatus { upcoming, draft, completed }

class HostHomeEvent {
  const HostHomeEvent({
    required this.id,
    required this.title,
    required this.formattedSchedule,
    required this.status,
    required this.soldCount,
    required this.capacity,
  });

  final String id;
  final String title;
  final String formattedSchedule;
  final HostEventStatus status;

  /// Tickets sold so far. `null` when unknown — the real
  /// `GET /api/v1/host/events` response has no sold-count field yet, so
  /// this stays null until the backend exposes one; showing a fabricated
  /// "0 of N sold" would be actively misleading rather than just missing.
  final int? soldCount;
  final int capacity;

  /// `"N of M sold"` when [soldCount] is known, otherwise just the
  /// capacity — never a guessed sold count.
  String get soldSummary =>
      soldCount == null ? '$capacity seats' : '$soldCount of $capacity sold';
}
