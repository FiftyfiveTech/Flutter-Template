import '../../domain/entities/host_venue_photo.dart';

/// Shape returned both by `POST /api/v1/uploads?fileType=venue_photo` and
/// nested in a venue detail/create/edit response's `photos` array. [url] is
/// a freshly presigned link each time — never cached beyond the response
/// that produced it.
class HostVenuePhotoDto {
  const HostVenuePhotoDto({required this.id, required this.url});

  factory HostVenuePhotoDto.fromJson(Map<String, dynamic> json) {
    return HostVenuePhotoDto(
      id: json['id'] as String,
      url: json['url'] as String,
    );
  }

  final String id;
  final String url;

  HostVenuePhoto toDomain() => HostVenuePhoto(id: id, url: url);
}
