/// What Home's event card shows. [inReview] = submitted, awaiting admin
/// approval; [live] = published and currently between start and end.
enum HostEventStatus { draft, inReview, upcoming, live, completed, cancelled }

class HostHomeEvent {
  const HostHomeEvent({
    required this.id,
    required this.title,
    required this.formattedSchedule,
    required this.status,
    required this.soldCount,
    required this.capacity,
    this.canCheckIn = false,
    this.avgRating,
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

  /// Whether the card offers door check-in: a published event that's
  /// live, about to start, or recently ended (so leftover offline scans
  /// can still sync and no-shows can be reviewed).
  final bool canCheckIn;

  /// Average guest rating; `null` until rated. Shown only for ended events.
  final double? avgRating;

  /// `"N of M sold"` when [soldCount] is known, otherwise just the
  /// capacity — never a guessed sold count.
  String get soldSummary =>
      soldCount == null ? '$capacity seats' : '$soldCount of $capacity sold';
}
