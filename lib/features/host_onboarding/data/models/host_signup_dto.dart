import '../../domain/entities/host_signup_draft.dart';
import '../../domain/entities/host_signup_result.dart';

/// Request body for `POST /api/v1/host/signup`.
class HostSignupRequestDto {
  const HostSignupRequestDto({
    required this.businessName,
    required this.phoneNumber,
    required this.contactEmail,
    required this.cityId,
  });

  final String businessName;
  final String phoneNumber;
  final String contactEmail;
  final String cityId;

  factory HostSignupRequestDto.fromDraft(HostSignupDraft draft) {
    return HostSignupRequestDto(
      businessName: draft.businessName,
      phoneNumber: _toE164(draft.contactPhone),
      contactEmail: draft.contactEmail,
      cityId: draft.cityId,
    );
  }

  /// The signup API rejects phone numbers without a country code. The
  /// client-side pattern in `ValidateHostSignupBasicsUseCase` allows a bare
  /// 10-13 digit number (no `+` required), so normalize to E.164 here —
  /// India-only for the pilot (`01-host-onboarding.md` §3), same assumption
  /// the city search is scoped to.
  static String _toE164(String phone) {
    return phone.startsWith('+') ? phone : '+91$phone';
  }

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'phoneNumber': phoneNumber,
    'contactEmail': contactEmail,
    'cityId': cityId,
  };
}

/// The `data` object of a successful signup response.
class HostSignupResponseDto {
  const HostSignupResponseDto({
    required this.accessToken,
    required this.userId,
    required this.accountStatus,
  });

  final String accessToken;
  final String userId;
  final String accountStatus;

  factory HostSignupResponseDto.fromJson(Map<String, dynamic> json) {
    return HostSignupResponseDto(
      accessToken: json['accessToken'] as String,
      userId: json['userId'] as String,
      accountStatus: json['accountStatus'] as String,
    );
  }

  HostSignupResult toEntity() => HostSignupResult(
    accessToken: accessToken,
    userId: userId,
    accountStatus: accountStatus,
  );
}
