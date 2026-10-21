import '../../../../shared/constants/event_types.dart';
import '../../domain/entities/host_event.dart';
import 'host_event_photo_dto.dart';

/// Request/response shape for `POST /api/v1/host/events`, confirmed
/// against a real response. A few backend concepts are richer than this
/// screen's UI, so they're collapsed to/from simpler domain fields:
/// - `ratioConfig.toleranceBandPoints` <-> [HostEvent.toleranceBandPoints]
///   (10 points = 50:50 ±10, 5 points = 55:45; `targetPercent` is always
///   50, this screen has no way to shift the target itself).
/// - `ratioConfig.releaseSchedule.minFemaleSeatsBeforeMaleRelease` <->
///   [HostEvent.holdbackEnabled] (0 = off, [kHoldbackFemaleSeatsThreshold]
///   = on).
/// - `ticketTypes` (a list of named tiers) <-> a single
///   [HostEvent.ticketPriceRupees] — this screen only offers one price, so
///   on write it's sent as one "General admission" tier covering the full
///   `capacity`; on read, the first ticket type's price is used and any
///   others are ignored (there are none yet since this is create-only).
/// - `startsAt`/`endsAt`/`doorsOpenAt` are sent as `yyyy-MM-dd HH:mm` in
///   the pilot's fixed `Asia/Kolkata` timezone (no timezone offset in the
///   request — the backend assumes Kolkata and returns UTC ISO strings).
/// - `coverPhotoId` (write) / `coverPhoto: {id, url} | null` (read) <->
///   [HostEvent.coverPhoto] — the single primary image.
/// - `photos` is the gallery: ids only on write (max 5, and a `PATCH`
///   replaces the whole array, not a merge), full `{id, url}` objects on
///   read.
class HostEventDto {
  const HostEventDto({
    required this.id,
    required this.title,
    required this.description,
    required this.format,
    required this.startAt,
    required this.endAt,
    required this.doorsOpenAt,
    required this.venueId,
    required this.venueName,
    required this.venueAddress,
    required this.neighbourhood,
    required this.capacity,
    required this.ticketPriceRupees,
    required this.toleranceBandPoints,
    required this.holdbackEnabled,
    required this.cancellationTerms,
    required this.refundCutoffHoursBeforeStart,
    required this.coverPhoto,
    required this.photos,
    required this.status,
  });

  factory HostEventDto.fromJson(Map<String, dynamic> json) {
    final ratioConfig = json['ratioConfig'] as Map<String, dynamic>?;
    final toleranceBandPoints =
        ((ratioConfig?['toleranceBandPoints'] as num?)?.toInt() ??
                kRatioBandMaxPoints)
            .clamp(kRatioBandMinPoints, kRatioBandMaxPoints);
    final releaseSchedule =
        ratioConfig?['releaseSchedule'] as Map<String, dynamic>?;
    final minFemaleSeatsBeforeMaleRelease =
        (releaseSchedule?['minFemaleSeatsBeforeMaleRelease'] as num?)
            ?.toInt() ??
        0;

    final ticketTypes = json['ticketTypes'] as List<dynamic>?;
    final firstTicketType = ticketTypes != null && ticketTypes.isNotEmpty
        ? ticketTypes.first as Map<String, dynamic>
        : null;
    final ticketPricePaise =
        (firstTicketType?['pricePaise'] as num?)?.toInt() ?? 0;

    return HostEventDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      format: eventTypeFromApi((json['format'] ?? '').toString()),
      startAt: _parseApiDateTime(json['startsAt']),
      endAt: _parseApiDateTime(json['endsAt']),
      doorsOpenAt: _parseApiDateTime(json['doorsOpenAt']),
      venueId: (json['venueId'] ?? '').toString(),
      venueName: (json['venueName'] ?? '').toString(),
      venueAddress: (json['venueExactAddress'] ?? '').toString(),
      neighbourhood: (json['neighbourhood'] ?? '').toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      ticketPriceRupees: (ticketPricePaise / 100).round(),
      toleranceBandPoints: toleranceBandPoints,
      holdbackEnabled: minFemaleSeatsBeforeMaleRelease > 0,
      cancellationTerms: (json['cancellationTerms'] ?? '').toString(),
      refundCutoffHoursBeforeStart:
          (json['refundCutoffHoursBeforeStart'] as num?)?.toInt() ?? 24,
      coverPhoto: json['coverPhoto'] == null
          ? null
          : HostEventPhotoDto.fromJson(
              json['coverPhoto'] as Map<String, dynamic>,
            ),
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((e) => HostEventPhotoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: _parseStatus(json['status']),
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
      doorsOpenAt: event.doorsOpenAt,
      venueId: event.venueId,
      venueName: event.venueName,
      venueAddress: event.venueAddress,
      neighbourhood: event.neighbourhood,
      capacity: event.capacity,
      ticketPriceRupees: event.ticketPriceRupees,
      toleranceBandPoints: event.toleranceBandPoints,
      holdbackEnabled: event.holdbackEnabled,
      cancellationTerms: event.cancellationTerms,
      refundCutoffHoursBeforeStart: event.refundCutoffHoursBeforeStart,
      coverPhoto: event.coverPhoto == null
          ? null
          : HostEventPhotoDto(
              id: event.coverPhoto!.id,
              url: event.coverPhoto!.url,
            ),
      photos: event.photos
          .map((p) => HostEventPhotoDto(id: p.id, url: p.url))
          .toList(),
      status: event.status,
    );
  }

  final String id;
  final String title;
  final String description;
  final String format;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? doorsOpenAt;
  final String venueId;
  final String venueName;
  final String venueAddress;
  final String neighbourhood;
  final int capacity;
  final int ticketPriceRupees;
  final int toleranceBandPoints;
  final bool holdbackEnabled;
  final String cancellationTerms;
  final int refundCutoffHoursBeforeStart;
  final HostEventPhotoDto? coverPhoto;
  final List<HostEventPhotoDto> photos;
  final HostEventLifecycleStatus status;

  /// Write payload for `POST`/`PATCH /api/v1/host/events`. `format` is
  /// sent as the backend's lowercase/underscored slug (e.g. "Board games"
  /// -> "board_games"), matching the backend's event-type enum
  /// (`dinner`, `tasting`, `pottery`, `board_games`, `party`, `music`,
  /// `dance`, `stand_up`, `other`). `coverPhotoId`/`photos` mirror
  /// `HostVenueDto.toJson`'s photo-id convention; `photos` always sends
  /// the full desired gallery list since `PATCH` replaces it wholesale.
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'format': eventTypeToApi(format),
    if (startAt != null) 'startsAt': _formatApiDateTime(startAt!),
    if (endAt != null) 'endsAt': _formatApiDateTime(endAt!),
    if (doorsOpenAt != null) 'doorsOpenAt': _formatApiDateTime(doorsOpenAt!),
    'venueId': venueId,
    'neighbourhood': neighbourhood,
    'capacity': capacity,
    'ratioConfig': {
      'targetPercent': 50,
      'toleranceBandPoints': toleranceBandPoints,
      'releaseSchedule': {
        'minFemaleSeatsBeforeMaleRelease': holdbackEnabled
            ? kHoldbackFemaleSeatsThreshold
            : 0,
      },
    },
    'ticketTypes': [
      {
        'name': 'General admission',
        'pricePaise': ticketPriceRupees * 100,
        'quantity': capacity,
        'active': true,
      },
    ],
    'cancellationTerms': cancellationTerms,
    'refundCutoffHoursBeforeStart': refundCutoffHoursBeforeStart,
    if (coverPhoto != null) 'coverPhotoId': coverPhoto!.id,
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
      doorsOpenAt: doorsOpenAt,
      venueId: venueId,
      venueName: venueName,
      venueAddress: venueAddress,
      neighbourhood: neighbourhood,
      capacity: capacity,
      ticketPriceRupees: ticketPriceRupees,
      toleranceBandPoints: toleranceBandPoints,
      holdbackEnabled: holdbackEnabled,
      cancellationTerms: cancellationTerms,
      refundCutoffHoursBeforeStart: refundCutoffHoursBeforeStart,
      coverPhoto: coverPhoto?.toDomain(),
      photos: photos.map((p) => p.toDomain()).toList(),
      status: status,
    );
  }
}

/// Maps the backend's lifecycle string to [HostEventLifecycleStatus],
/// per `docs/features/host-app/02-host-event-publishing.md`'s
/// `draft/submitted/published` states — anything else falls back to
/// [HostEventLifecycleStatus.unknown] rather than crashing.
HostEventLifecycleStatus _parseStatus(Object? value) {
  return switch (value?.toString()) {
    'draft' => HostEventLifecycleStatus.draft,
    'submitted' => HostEventLifecycleStatus.submitted,
    'published' => HostEventLifecycleStatus.published,
    'cancelled' => HostEventLifecycleStatus.cancelled,
    'completed' => HostEventLifecycleStatus.completed,
    _ => HostEventLifecycleStatus.unknown,
  };
}

/// `yyyy-MM-dd HH:mm`, matching the request example exactly (no timezone
/// offset — the backend assumes `Asia/Kolkata`).
String _formatApiDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}

/// The response returns full UTC ISO-8601 strings (e.g.
/// `2026-10-10T13:00:00.000Z`) — converted back to local time so a
/// resumed/read-back form shows the same wall-clock time the host entered.
DateTime? _parseApiDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.parse(value as String).toLocal();
}
