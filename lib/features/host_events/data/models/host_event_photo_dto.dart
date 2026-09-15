import '../../domain/entities/host_event_photo.dart';

/// Shape returned both by `POST /api/v1/uploads?fileType=event_photo` and
/// nested in an event create/edit response's `photos` array. Mirrors
/// `HostVenuePhotoDto`.
class HostEventPhotoDto {
  const HostEventPhotoDto({required this.id, required this.url});

  factory HostEventPhotoDto.fromJson(Map<String, dynamic> json) {
    return HostEventPhotoDto(
      id: json['id'] as String,
      url: json['url'] as String,
    );
  }

  final String id;
  final String url;

  HostEventPhoto toDomain() => HostEventPhoto(id: id, url: url);
}
