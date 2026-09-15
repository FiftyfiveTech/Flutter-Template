import '../../domain/entities/host_event.dart';
import 'host_event_photo_dto.dart';

/// Assumed request/response shape for the not-yet-specified events
/// endpoint, modelled directly on `HostVenueDto`'s conventions:
/// `startAt`/`endAt` as ISO-8601 strings, ratio band expressed as an
/// explicit `ratioTightened` boolean (the backend derives 50:50 ±10 vs
/// 55:45 from it), price in whole rupees, and photos sent as ids only on
/// write with the full `{id, url}` shape coming back on read.
class HostEventDto {
  const HostEventDto({
    required this.id,
    required this.title,
    required this.description,
    required this.format,
    required this.startAt,
    required this.endAt,
    required this.venueId,
    required this.venueAddress,
    required this.capacity,
    required this.ticketPriceRupees,
    required this.ratioTightened,
    required this.holdbackEnabled,
    required this.cancellationTerms,
    required this.photos,
  });

  factory HostEventDto.fromJson(Map<String, dynamic> json) {
    final venueJson = json['venue'];
    final String venueId;
    final String venueAddress;
    if (venueJson is Map<String, dynamic>) {
      venueId = (venueJson['id'] ?? venueJson['_id'] ?? '').toString();
      venueAddress = (venueJson['address'] ?? '').toString();
    } else {
      venueId = (venueJson ?? '').toString();
      venueAddress = '';
    }
    return HostEventDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      format: json['format'] as String? ?? '',
      startAt: json['startAt'] == null
          ? null
          : DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] == null
          ? null
          : DateTime.parse(json['endAt'] as String),
      venueId: venueId,
      venueAddress: venueAddress,
      capacity: (json['capacity'] as num).toInt(),
      ticketPriceRupees: (json['ticketPriceRupees'] as num).toInt(),
      ratioTightened: json['ratioTightened'] as bool? ?? false,
      holdbackEnabled: json['holdbackEnabled'] as bool? ?? false,
      cancellationTerms: json['cancellationTerms'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((e) => HostEventPhotoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory HostEventDto.fromDomain(HostEvent event) {
    return HostEventDto(
      id: event.id,
      title: event.title,
      description: event.description,
      format: event.format,
      startAt: event.startAt,
      endAt: event.endAt,
      venueId: event.venueId,
      venueAddress: event.venueAddress,
      capacity: event.capacity,
      ticketPriceRupees: event.ticketPriceRupees,
      ratioTightened: event.ratioTightened,
      holdbackEnabled: event.holdbackEnabled,
      cancellationTerms: event.cancellationTerms,
      photos: event.photos
          .map((p) => HostEventPhotoDto(id: p.id, url: p.url))
          .toList(),
    );
  }

  final String id;
  final String title;
  final String description;
  final String format;
  final DateTime? startAt;
  final DateTime? endAt;
  final String venueId;
  final String venueAddress;
  final int capacity;
  final int ticketPriceRupees;
  final bool ratioTightened;
  final bool holdbackEnabled;
  final String cancellationTerms;
  final List<HostEventPhotoDto> photos;

  /// Write payload for `POST /api/v1/events`. `venue` is sent as the bare
  /// venue id — `venueAddress` is UI-only display copy filled from the
  /// venue record and never sent. Photos are sent as ids only, mirroring
  /// `HostVenueDto.toJson`.
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'format': format,
    if (startAt != null) 'startAt': startAt!.toIso8601String(),
    if (endAt != null) 'endAt': endAt!.toIso8601String(),
    'venue': venueId,
    'capacity': capacity,
    'ticketPriceRupees': ticketPriceRupees,
    'ratioTightened': ratioTightened,
    'holdbackEnabled': holdbackEnabled,
    'cancellationTerms': cancellationTerms,
    'photos': photos.map((p) => p.id).toList(),
  };

  HostEvent toDomain() {
    return HostEvent(
      id: id,
      title: title,
      description: description,
      format: format,
      startAt: startAt,
      endAt: endAt,
      venueId: venueId,
      venueAddress: venueAddress,
      capacity: capacity,
      ticketPriceRupees: ticketPriceRupees,
      ratioTightened: ratioTightened,
      holdbackEnabled: holdbackEnabled,
      cancellationTerms: cancellationTerms,
      photos: photos.map((p) => p.toDomain()).toList(),
    );
  }
}
