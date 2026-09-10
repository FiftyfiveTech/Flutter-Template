import '../../domain/entities/host_login_result.dart';

/// The OTP request/verify APIs reject phone numbers without a country
/// code. The client-side pattern in `ValidatePhoneNumberUseCase` allows a
/// bare 10-13 digit number (no `+` required), so normalize to E.164 here —
/// India-only for the pilot, same assumption host signup makes.
String _toE164(String phone) {
  return phone.startsWith('+') ? phone : '+91$phone';
}

/// Request body for `POST /api/v1/host/auth/otp/request`.
class OtpRequestDto {
  const OtpRequestDto({required this.phoneNumber});

  final String phoneNumber;

  factory OtpRequestDto.fromPhoneNumber(String phoneNumber) {
    return OtpRequestDto(phoneNumber: _toE164(phoneNumber));
  }

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber};
}

/// Request body for `POST /api/v1/host/auth/otp/verify`.
class OtpVerifyRequestDto {
  const OtpVerifyRequestDto({required this.phoneNumber, required this.code});

  final String phoneNumber;
  final String code;

  factory OtpVerifyRequestDto.from(String phoneNumber, String code) {
    return OtpVerifyRequestDto(phoneNumber: _toE164(phoneNumber), code: code);
  }

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber, 'code': code};
}

/// The `data` object of a successful OTP verification response.
class OtpVerifyResponseDto {
  const OtpVerifyResponseDto({
    required this.accessToken,
    required this.userId,
    required this.accountStatus,
  });

  final String accessToken;
  final String userId;
  final String accountStatus;

  factory OtpVerifyResponseDto.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponseDto(
      accessToken: json['accessToken'] as String,
      userId: json['hostId'] as String,
      accountStatus: json['accountStatus'] as String,
    );
  }

  HostLoginResult toEntity() => HostLoginResult(
    accessToken: accessToken,
    userId: userId,
    accountStatus: accountStatus,
  );
}
