import 'host_home_event.dart';

class HostHomeSummary {
  const HostHomeSummary({
    required this.hostName,
    required this.isVerified,
    required this.savedVenuesCount,
    required this.events,
  });

  final String hostName;
  final bool isVerified;
  final int savedVenuesCount;
  final List<HostHomeEvent> events;

  HostHomeSummary copyWith({
    String? hostName,
    bool? isVerified,
    int? savedVenuesCount,
    List<HostHomeEvent>? events,
  }) {
    return HostHomeSummary(
      hostName: hostName ?? this.hostName,
      isVerified: isVerified ?? this.isVerified,
      savedVenuesCount: savedVenuesCount ?? this.savedVenuesCount,
      events: events ?? this.events,
    );
  }
}
