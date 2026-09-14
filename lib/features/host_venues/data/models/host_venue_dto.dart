import '../../domain/entities/host_venue.dart';

class HostVenueDto {
  const HostVenueDto({
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

  factory HostVenueDto.fromJson(Map<String, dynamic> json) {
    return HostVenueDto(
      id: json['id'] as String,
      name: json['name'] as String,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String? ?? '',
      city: json['city'] as String,
      pincode: json['pincode'] as String,
      maxCapacity: (json['maxCapacity'] as num).toInt(),
      eventTypes: (json['eventTypes'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      photoPaths: (json['photoPaths'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  factory HostVenueDto.fromDomain(HostVenue venue) {
    return HostVenueDto(
      id: venue.id,
      name: venue.name,
      addressLine1: venue.addressLine1,
      addressLine2: venue.addressLine2,
      city: venue.city,
      pincode: venue.pincode,
      maxCapacity: venue.maxCapacity,
      eventTypes: venue.eventTypes,
      photoPaths: venue.photoPaths,
    );
  }

  final String id;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String pincode;
  final int maxCapacity;
  final List<String> eventTypes;
  final List<String> photoPaths;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'pincode': pincode,
    'maxCapacity': maxCapacity,
    'eventTypes': eventTypes,
    'photoPaths': photoPaths,
  };

  HostVenue toDomain() {
    return HostVenue(
      id: id,
      name: name,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      pincode: pincode,
      maxCapacity: maxCapacity,
      eventTypes: eventTypes,
      photoPaths: photoPaths,
    );
  }
}
