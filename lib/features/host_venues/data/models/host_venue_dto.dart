import '../../../../shared/constants/venue_types.dart';
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
    required this.allowedVenueTypes,
    required this.photos,
  });

  /// `GET /api/v1/venues` list items are a minimal projection — they omit
  /// `photos`, and (per an observed real response) also omit
  /// `maxCapacity`/`allowedVenueTypes` entirely. Only `GET
  /// /api/v1/venues/:id` and the create/edit responses include the full
  /// shape. Every field here is parsed defensively (falling back to an
  /// empty/zero value rather than throwing) so a minimal list item never
  /// breaks `getVenues()` — the alternative is a hard-to-notice list-wide
  /// failure like the one this defensiveness was added to fix.
  ///
  /// `city` is documented as a plain ObjectId string on write. On read it
  /// may come back the same way (id only, no name to show) or expanded —
  /// an observed real response uses `{id, city, slug}` rather than
  /// `{id, name}`, so both `name` and `city` are checked for the display
  /// value.
  factory HostVenueDto.fromJson(Map<String, dynamic> json) {
    final cityJson = json['city'];
    final String cityId;
    final String cityName;
    if (cityJson is Map<String, dynamic>) {
      cityId = (cityJson['id'] ?? cityJson['_id'] ?? '').toString();
      cityName = (cityJson['name'] ?? cityJson['city'] ?? '').toString();
    } else {
      cityId = (cityJson ?? '').toString();
      cityName = '';
    }
    return HostVenueDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      addLine1: (json['addLine1'] ?? '').toString(),
      addLine2: (json['addLine2'] ?? '').toString(),
      locality: (json['locality'] ?? '').toString(),
      cityId: cityId,
      cityName: cityName,
      pincode: (json['pincode'] ?? '').toString(),
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 0,
      allowedVenueTypes: (json['allowedVenueTypes'] as List<dynamic>? ?? [])
          .map((e) => venueTypeFromApi(e.toString()))
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
      allowedVenueTypes: venue.allowedVenueTypes,
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
  final List<String> allowedVenueTypes;
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
    // Backend enum values (e.g. `board_games`), not the display labels.
    'allowedVenueTypes': allowedVenueTypes.map(venueTypeToApi).toList(),
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
      allowedVenueTypes: allowedVenueTypes,
      photos: photos.map((p) => p.toDomain()).toList(),
    );
  }
}
