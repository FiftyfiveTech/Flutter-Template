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
  final int soldCount;
  final int capacity;

  String get soldSummary => '$soldCount of $capacity sold';
}
