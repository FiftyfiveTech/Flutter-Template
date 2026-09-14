/// A single venue saved by a host. Reused across every event created there.
class HostVenue {
  const HostVenue({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.pincode,
    required this.maxCapacity,
    required this.eventTypes,
    required this.photoPaths,
  });

  final String id;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String pincode;
  final int maxCapacity;
  final List<String> eventTypes;

  /// Local or remote references to the venue's photos. At least 3 are
  /// required before the venue can be saved.
  final List<String> photoPaths;

  /// Single-line summary used on the H-06 list row, e.g. "12, 100 Feet
  /// Road, Indiranagar, Bangalore".
  String get address {
    final parts = [
      addressLine1,
      addressLine2,
      city,
    ].where((part) => part.trim().isNotEmpty);
    return parts.join(', ');
  }

  HostVenue copyWith({
    String? id,
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? pincode,
    int? maxCapacity,
    List<String>? eventTypes,
    List<String>? photoPaths,
  }) {
    return HostVenue(
      id: id ?? this.id,
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      eventTypes: eventTypes ?? this.eventTypes,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  /// An empty draft used to seed the H-E0 "add a venue" form.
  static const empty = HostVenue(
    id: '',
    name: '',
    addressLine1: '',
    addressLine2: '',
    city: '',
    pincode: '',
    maxCapacity: 30,
    eventTypes: [],
    photoPaths: [],
  );
}
