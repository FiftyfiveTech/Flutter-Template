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
}
