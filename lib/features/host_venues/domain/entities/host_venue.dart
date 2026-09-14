import 'host_venue_photo.dart';

/// A single venue saved by a host. Reused across every event created there.
class HostVenue {
  const HostVenue({
    required this.id,
    required this.name,
    required this.addLine1,
    required this.addLine2,
    required this.locality,
    required this.cityId,
    required this.cityName,
    required this.pincode,
    required this.maxCapacity,
    required this.allowedEventTypes,
    required this.photos,
  });

  final String id;

  /// 1 to 200 characters.
  final String name;

  /// 1 to 200 characters.
  final String addLine1;

  /// Optional, 1 to 200 characters when present.
  final String addLine2;

  /// 1 to 100 characters, e.g. "Indiranagar", "Koramangala".
  final String locality;

  /// The backend city id (a 24-character MongoDB ObjectId from
  /// `GET /api/v1/cities`) — this, not [cityName], is what's sent as the
  /// venue's `city` field.
  final String cityId;

  /// Display name of the city backing [cityId], from the H-07 city
  /// typeahead. Not sent to the API directly.
  final String cityName;

  /// 1 to 12 characters, e.g. "560038".
  final String pincode;

  /// Minimum 1.
  final int maxCapacity;

  /// One or more of the backend's fixed event-type vocabulary (see
  /// `kVenueEventTypeOptions`).
  final List<String> allowedEventTypes;

  /// Already-uploaded photos for this venue. Optional, max 5. Note: the
  /// list endpoint (`GET /api/v1/venues`) never populates this — only the
  /// detail and create/edit responses do.
  final List<HostVenuePhoto> photos;

  /// Single-line summary used on the H-06 list row, e.g. "12, 100 Feet
  /// Road, Indiranagar, Bangalore".
  String get address {
    final parts = [
      addLine1,
      addLine2,
      locality,
      cityName,
    ].where((part) => part.trim().isNotEmpty);
    return parts.join(', ');
  }

  HostVenue copyWith({
    String? id,
    String? name,
    String? addLine1,
    String? addLine2,
    String? locality,
    String? cityId,
    String? cityName,
    String? pincode,
    int? maxCapacity,
    List<String>? allowedEventTypes,
    List<HostVenuePhoto>? photos,
  }) {
    return HostVenue(
      id: id ?? this.id,
      name: name ?? this.name,
      addLine1: addLine1 ?? this.addLine1,
      addLine2: addLine2 ?? this.addLine2,
      locality: locality ?? this.locality,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      pincode: pincode ?? this.pincode,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      allowedEventTypes: allowedEventTypes ?? this.allowedEventTypes,
      photos: photos ?? this.photos,
    );
  }

  /// An empty draft used to seed the H-E0 "add a venue" form.
  static const empty = HostVenue(
    id: '',
    name: '',
    addLine1: '',
    addLine2: '',
    locality: '',
    cityId: '',
    cityName: '',
    pincode: '',
    maxCapacity: 20,
    allowedEventTypes: [],
    photos: [],
  );
}
