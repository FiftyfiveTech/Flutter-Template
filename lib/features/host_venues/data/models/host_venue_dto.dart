import '../../domain/entities/host_venue.dart';
import 'host_venue_photo_dto.dart';

class HostVenueDto {
  const HostVenueDto({
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

  /// `GET /api/v1/venues` items omit `photos` entirely; `GET
  /// /api/v1/venues/:id` and the create/edit responses include it as
  /// `[{id, url}, ...]`.
  ///
  /// `city` is documented as a plain ObjectId string on write. On read it
  /// may come back either the same way (id only, no name to show) or
  /// expanded into `{id, name}` — both shapes are accepted here so an
  /// edit screen can still show a name when the backend provides one.
  factory HostVenueDto.fromJson(Map<String, dynamic> json) {
    final cityJson = json['city'];
    final String cityId;
    final String cityName;
    if (cityJson is Map<String, dynamic>) {
      cityId = (cityJson['id'] ?? cityJson['_id'] ?? '').toString();
      cityName = (cityJson['name'] ?? '').toString();
    } else {
      cityId = (cityJson ?? '').toString();
      cityName = '';
    }
    return HostVenueDto(
      id: json['id'] as String,
      name: json['name'] as String,
      addLine1: json['addLine1'] as String,
      addLine2: json['addLine2'] as String? ?? '',
      locality: json['locality'] as String? ?? '',
      cityId: cityId,
      cityName: cityName,
      pincode: json['pincode'] as String,
      maxCapacity: (json['maxCapacity'] as num).toInt(),
      allowedEventTypes: (json['allowedEventTypes'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((e) => HostVenuePhotoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory HostVenueDto.fromDomain(HostVenue venue) {
    return HostVenueDto(
      id: venue.id,
      name: venue.name,
      addLine1: venue.addLine1,
      addLine2: venue.addLine2,
      locality: venue.locality,
      cityId: venue.cityId,
      cityName: venue.cityName,
      pincode: venue.pincode,
      maxCapacity: venue.maxCapacity,
      allowedEventTypes: venue.allowedEventTypes,
      photos: venue.photos
          .map((p) => HostVenuePhotoDto(id: p.id, url: p.url))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String addLine1;
  final String addLine2;
  final String locality;
  final String cityId;
  final String cityName;
  final String pincode;
  final int maxCapacity;
  final List<String> allowedEventTypes;
  final List<HostVenuePhotoDto> photos;

  /// Write payload for `POST`/`PATCH`. `city` is sent as the bare ObjectId
  /// string per the backend contract — `cityName` is UI-only and never
  /// sent. Photos are sent as ids only (the backend returns the full
  /// `{id, url}` shape back on the response), and a `PATCH` always
  /// replaces the whole array, so callers must pass the full desired list
  /// rather than a diff. `addLine2` is omitted entirely when blank, since
  /// it's an optional field.
  Map<String, dynamic> toJson() => {
    'name': name,
    'addLine1': addLine1,
    if (addLine2.trim().isNotEmpty) 'addLine2': addLine2,
    'locality': locality,
    'city': cityId,
    'pincode': pincode,
    'maxCapacity': maxCapacity,
    'allowedEventTypes': allowedEventTypes,
    'photos': photos.map((p) => p.id).toList(),
  };

  HostVenue toDomain() {
    return HostVenue(
      id: id,
      name: name,
      addLine1: addLine1,
      addLine2: addLine2,
      locality: locality,
      cityId: cityId,
      cityName: cityName,
      pincode: pincode,
      maxCapacity: maxCapacity,
      allowedEventTypes: allowedEventTypes,
      photos: photos.map((p) => p.toDomain()).toList(),
    );
  }
}
