import 'host_event_photo.dart';

/// Default "hold back male seats" threshold shown in H-08's copy ("until 8
/// women have booked") — the backend's `releaseSchedule` config is a raw
/// seat count, not a boolean, so this is the value sent when the switch is
/// on (0 when off).
const kHoldbackFemaleSeatsThreshold = 8;

/// An event's publish lifecycle, per `docs/features/host-app/
/// 02-host-event-publishing.md`'s `Event` entity (`draft/submitted/
/// published`), plus the `cancelled/completed` states the API also
/// returns. [unknown] is a safe fallback for any value the backend adds
/// later that the client doesn't recognize yet, rather than crashing.
enum HostEventLifecycleStatus {
  draft,
  submitted,
  published,
  cancelled,
  completed,
  unknown,
}

/// The platform-default, widest-allowed ratio band tolerance (50:50 ±10).
const kRatioBandMaxPoints = 10;

/// The tightest ratio band tolerance a host may pick (55:45).
const kRatioBandMinPoints = 5;

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

  final String id;

  /// 1 to 200 characters.
  final String title;

  /// 1 to 2000 characters.
  final String description;

  /// One of the shared `kEventTypeOptions` vocabulary (see
  /// `lib/shared/constants/event_types.dart`) — the same fixed list a
  /// venue's `allowedEventTypes` draws from in H-07.
  final String format;

  final DateTime? startAt;
  final DateTime? endAt;

  /// When doors open for check-in — may be before [startAt].
  final DateTime? doorsOpenAt;

  /// Whether the event is over as of [now] (pass server-corrected time).
  /// The backend keeps a finished event `published` rather than moving it
  /// to `completed`, so a published event counts as ended once its end
  /// time has passed — or its start, when it has no end time, since
  /// there's then no way to tell how long it runs.
  bool hasEndedAt(DateTime now) {
    if (status == HostEventLifecycleStatus.completed) return true;
    if (status != HostEventLifecycleStatus.published) return false;
    final end = endAt ?? startAt;
    return end != null && !now.isBefore(end);
  }

  /// The backend venue id this event is held at.
  final String venueId;

  /// The venue's display name, as returned by the backend — not sent on
  /// write, only populated when reading an existing event back (e.g. for
  /// the H-05 Home event list).
  final String venueName;

  /// Read-only display copy of the selected venue's full address — filled
  /// from the venue record and never edited on this screen.
  final String venueAddress;

  /// Read-only copy of the selected venue's locality/neighbourhood — filled
  /// from the venue record, same as [venueAddress].
  final String neighbourhood;

  /// 8 to 200, in steps of 2. May additionally be capped by the venue's
  /// `maxCapacity` in the UI layer.
  final int capacity;

  /// Price per seat, in whole rupees. The backend models multiple named
  /// ticket tiers (`ticketTypes`); this screen only offers a single price,
  /// sent as one "General admission" tier covering the full capacity.
  final int ticketPriceRupees;

  /// The ratio band's tolerance in percentage points, from
  /// [kRatioBandMinPoints] (tightest, "55:45") to [kRatioBandMaxPoints]
  /// (the platform default, "50:50 ±10") — can only be narrowed, never
  /// widened past the default.
  final int toleranceBandPoints;

  /// Whether male seats are held back until
  /// [kHoldbackFemaleSeatsThreshold] women have booked.
  final bool holdbackEnabled;

  /// 1 to 2000 characters.
  final String cancellationTerms;

  /// Hours before [startAt] after which no refund is offered.
  final int refundCutoffHoursBeforeStart;

  /// The event's single primary/cover image — optional per the backend,
  /// but this screen's own UX requires at least 3 photos total across
  /// [coverPhoto] and [photos] before submitting.
  final HostEventPhoto? coverPhoto;

  /// Gallery photos for this event, beyond [coverPhoto]. Optional, max 5.
  final List<HostEventPhoto> photos;

  /// The event's publish lifecycle — not sent on write, only populated
  /// when reading an existing event back.
  final HostEventLifecycleStatus status;

  String get ratioBandLabel => toleranceBandPoints <= kRatioBandMinPoints
      ? '55:45'
      : '50:50 ±$toleranceBandPoints';

  HostEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? format,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? doorsOpenAt,
    String? venueId,
    String? venueName,
    String? venueAddress,
    String? neighbourhood,
    int? capacity,
    int? ticketPriceRupees,
    int? toleranceBandPoints,
    bool? holdbackEnabled,
    String? cancellationTerms,
    int? refundCutoffHoursBeforeStart,
    HostEventPhoto? coverPhoto,
    List<HostEventPhoto>? photos,
    HostEventLifecycleStatus? status,
  }) {
    return HostEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      format: format ?? this.format,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      doorsOpenAt: doorsOpenAt ?? this.doorsOpenAt,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      neighbourhood: neighbourhood ?? this.neighbourhood,
      capacity: capacity ?? this.capacity,
      ticketPriceRupees: ticketPriceRupees ?? this.ticketPriceRupees,
      toleranceBandPoints: toleranceBandPoints ?? this.toleranceBandPoints,
      holdbackEnabled: holdbackEnabled ?? this.holdbackEnabled,
      cancellationTerms: cancellationTerms ?? this.cancellationTerms,
      refundCutoffHoursBeforeStart:
          refundCutoffHoursBeforeStart ?? this.refundCutoffHoursBeforeStart,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      photos: photos ?? this.photos,
      status: status ?? this.status,
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
    doorsOpenAt: null,
    venueId: '',
    venueName: '',
    venueAddress: '',
    neighbourhood: '',
    capacity: 20,
    ticketPriceRupees: 0,
    toleranceBandPoints: kRatioBandMaxPoints,
    holdbackEnabled: false,
    cancellationTerms: '',
    refundCutoffHoursBeforeStart: 24,
    coverPhoto: null,
    photos: [],
    status: HostEventLifecycleStatus.draft,
  );
}
