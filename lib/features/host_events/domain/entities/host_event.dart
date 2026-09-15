import 'host_event_photo.dart';

/// A single event authored by a host at one of their saved venues. This
/// entity currently only supports the H-08 create flow — editing an
/// existing event (with its "locked after first sale" rules) is H-E1,
/// out of scope here.
class HostEvent {
  const HostEvent({
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

  final String id;

  /// 1 to 200 characters.
  final String title;

  /// 1 to 2000 characters.
  final String description;

  /// One of the selected venue's `allowedEventTypes` — the format vocabulary
  /// is per-venue, not a separate fixed list (see H-07's `allowedEventTypes`).
  final String format;

  final DateTime? startAt;
  final DateTime? endAt;

  /// The backend venue id this event is held at.
  final String venueId;

  /// Read-only display copy of the selected venue's full address — filled
  /// from the venue record and never edited on this screen.
  final String venueAddress;

  /// 8 to 200, in steps of 2. May additionally be capped by the venue's
  /// `maxCapacity` in the UI layer.
  final int capacity;

  /// Price per seat, in whole rupees.
  final int ticketPriceRupees;

  /// Whether the host narrowed the default 50:50 ±10 ratio band to 55:45.
  /// The band can only be tightened, never widened, per platform policy.
  final bool ratioTightened;

  /// Whether male seats are held back until 8 women have booked.
  final bool holdbackEnabled;

  /// 1 to 2000 characters.
  final String cancellationTerms;

  /// Cover photos for this event. Minimum 3 required to publish.
  final List<HostEventPhoto> photos;

  /// The ratio band's female:male tolerance in percentage points, derived
  /// from [ratioTightened] — 50:50 ±10 by default, tightened to 55:45.
  String get ratioBandLabel => ratioTightened ? '55:45' : '50:50 ±10';

  HostEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? format,
    DateTime? startAt,
    DateTime? endAt,
    String? venueId,
    String? venueAddress,
    int? capacity,
    int? ticketPriceRupees,
    bool? ratioTightened,
    bool? holdbackEnabled,
    String? cancellationTerms,
    List<HostEventPhoto>? photos,
  }) {
    return HostEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      format: format ?? this.format,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      venueId: venueId ?? this.venueId,
      venueAddress: venueAddress ?? this.venueAddress,
      capacity: capacity ?? this.capacity,
      ticketPriceRupees: ticketPriceRupees ?? this.ticketPriceRupees,
      ratioTightened: ratioTightened ?? this.ratioTightened,
      holdbackEnabled: holdbackEnabled ?? this.holdbackEnabled,
      cancellationTerms: cancellationTerms ?? this.cancellationTerms,
      photos: photos ?? this.photos,
    );
  }

  /// An empty draft used to seed the H-08 "new event" form.
  static const empty = HostEvent(
    id: '',
    title: '',
    description: '',
    format: '',
    startAt: null,
    endAt: null,
    venueId: '',
    venueAddress: '',
    capacity: 20,
    ticketPriceRupees: 0,
    ratioTightened: false,
    holdbackEnabled: false,
    cancellationTerms: '',
    photos: [],
  );
}
