import '../../domain/entities/host_profile_edit.dart';

/// Request body for `PATCH /api/v1/host/profile` (`UpdateHostProfileDto`).
/// Only set fields are sent — an omitted field is left unchanged.
class UpdateHostProfileRequestDto {
  const UpdateHostProfileRequestDto({
    this.firstName,
    this.lastName,
    this.businessName,
    this.photoUploadId,
  });

  factory UpdateHostProfileRequestDto.fromEdit(
    HostProfileEdit edit, {
    String? photoUploadId,
  }) {
    return UpdateHostProfileRequestDto(
      firstName: edit.firstName,
      lastName: edit.lastName,
      businessName: edit.businessName,
      photoUploadId: photoUploadId,
    );
  }

  final String? firstName;
  final String? lastName;
  final String? businessName;

  /// `id` from `POST /api/v1/uploads?fileType=profile_photo`.
  final String? photoUploadId;

  Map<String, dynamic> toJson() => {
    'firstName': ?firstName,
    'lastName': ?lastName,
    'businessName': ?businessName,
    'photoUploadId': ?photoUploadId,
  };
}

/// The `data` object of `GET /api/v1/host` and `PATCH /api/v1/host/profile`
/// (`HostProfileResponseDto`). Only the fields the app uses are mapped;
/// [photoUrl] is a short-lived presigned URL, so it's shown but never
/// cached — a locally stored avatar copy is preferred when there is one.
class HostProfileResponseDto {
  const HostProfileResponseDto({
    required this.id,
    this.firstName,
    this.lastName,
    this.businessName,
    this.photoUrl,
    this.verificationStatus,
  });

  factory HostProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return HostProfileResponseDto(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      businessName: json['businessName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
    );
  }

  final String id;
  final String? firstName;
  final String? lastName;
  final String? businessName;
  final String? photoUrl;
  final String? verificationStatus;

  bool get isVerified => verificationStatus == 'verified';
}

/// The `data` object of `POST /api/v1/uploads` (`UploadResponseDto`).
class HostProfileUploadDto {
  const HostProfileUploadDto({required this.id});

  factory HostProfileUploadDto.fromJson(Map<String, dynamic> json) {
    return HostProfileUploadDto(id: json['id'] as String);
  }

  final String id;
}
