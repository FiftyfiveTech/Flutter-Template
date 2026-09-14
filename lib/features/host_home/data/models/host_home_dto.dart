import '../../domain/entities/host_home_event.dart';
import '../../domain/entities/host_home_summary.dart';

class HostHomeEventDto {
  const HostHomeEventDto({
    required this.id,
    required this.title,
    required this.formattedSchedule,
    required this.status,
    required this.soldCount,
    required this.capacity,
  });

  factory HostHomeEventDto.fromJson(Map<String, dynamic> json) {
    return HostHomeEventDto(
      id: json['id'] as String,
      title: json['title'] as String,
      formattedSchedule: json['formattedSchedule'] as String,
      status: json['status'] as String,
      soldCount: (json['soldCount'] as num).toInt(),
      capacity: (json['capacity'] as num).toInt(),
    );
  }

  final String id;
  final String title;
  final String formattedSchedule;
  final String status;
  final int soldCount;
  final int capacity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'formattedSchedule': formattedSchedule,
    'status': status,
    'soldCount': soldCount,
    'capacity': capacity,
  };

  HostHomeEvent toDomain() {
    final domainStatus = switch (status.toLowerCase()) {
      'upcoming' => HostEventStatus.upcoming,
      'draft' => HostEventStatus.draft,
      'completed' => HostEventStatus.completed,
      _ => HostEventStatus.draft,
    };

    return HostHomeEvent(
      id: id,
      title: title,
      formattedSchedule: formattedSchedule,
      status: domainStatus,
      soldCount: soldCount,
      capacity: capacity,
    );
  }
}

class HostHomeSummaryDto {
  const HostHomeSummaryDto({
    required this.hostName,
    required this.isVerified,
    required this.savedVenuesCount,
    required this.events,
  });

  factory HostHomeSummaryDto.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'] as List<dynamic>? ?? [];
    return HostHomeSummaryDto(
      hostName: json['hostName'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      savedVenuesCount: (json['savedVenuesCount'] as num?)?.toInt() ?? 0,
      events: eventsRaw
          .map((e) => HostHomeEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String hostName;
  final bool isVerified;
  final int savedVenuesCount;
  final List<HostHomeEventDto> events;

  Map<String, dynamic> toJson() => {
    'hostName': hostName,
    'isVerified': isVerified,
    'savedVenuesCount': savedVenuesCount,
    'events': events.map((e) => e.toJson()).toList(),
  };

  HostHomeSummary toDomain() {
    return HostHomeSummary(
      hostName: hostName,
      isVerified: isVerified,
      savedVenuesCount: savedVenuesCount,
      events: events.map((e) => e.toDomain()).toList(),
    );
  }
}
