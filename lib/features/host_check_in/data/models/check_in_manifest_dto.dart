import '../../domain/entities/check_in_manifest.dart';

/// One guest of `GET .../checkin/manifest`. Also the shape the attendees
/// are cached in locally ([toJson]).
class CheckInManifestAttendeeDto {
  const CheckInManifestAttendeeDto({
    required this.bookingId,
    required this.userId,
    required this.firstName,
    required this.qrCodeHash,
    required this.alreadyCheckedIn,
    this.photoUrl,
  });

  factory CheckInManifestAttendeeDto.fromJson(Map<String, dynamic> json) {
    return CheckInManifestAttendeeDto(
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      qrCodeHash: json['qrCodeHash'] as String? ?? '',
      alreadyCheckedIn: json['alreadyCheckedIn'] as bool? ?? false,
    );
  }

  final String bookingId;
  final String userId;
  final String firstName;
  final String? photoUrl;
  final String qrCodeHash;
  final bool alreadyCheckedIn;

  CheckInManifestAttendeeDto markedCheckedIn() => CheckInManifestAttendeeDto(
    bookingId: bookingId,
    userId: userId,
    firstName: firstName,
    photoUrl: photoUrl,
    qrCodeHash: qrCodeHash,
    alreadyCheckedIn: true,
  );

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'userId': userId,
    'firstName': firstName,
    'photoUrl': photoUrl,
    'qrCodeHash': qrCodeHash,
    'alreadyCheckedIn': alreadyCheckedIn,
  };

  CheckInManifestAttendee toDomain() => CheckInManifestAttendee(
    bookingId: bookingId,
    userId: userId,
    firstName: firstName,
    photoUrl: photoUrl,
    qrCodeHash: qrCodeHash,
    alreadyCheckedIn: alreadyCheckedIn,
  );
}

/// `GET .../checkin/manifest` response `data`.
class CheckInManifestDto {
  const CheckInManifestDto({
    required this.manifestVersion,
    required this.serverSignature,
    required this.issuedAt,
    required this.expiresAt,
    required this.attendees,
  });

  factory CheckInManifestDto.fromJson(Map<String, dynamic> json) {
    return CheckInManifestDto(
      manifestVersion: (json['manifestVersion'] as num?)?.toInt() ?? 0,
      serverSignature: json['serverSignature'] as String? ?? '',
      issuedAt: DateTime.parse(json['issuedAt'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
      attendees: (json['attendees'] as List<dynamic>? ?? const [])
          .map(
            (e) =>
                CheckInManifestAttendeeDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int manifestVersion;
  final String serverSignature;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final List<CheckInManifestAttendeeDto> attendees;
}
