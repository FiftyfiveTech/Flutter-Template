import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Field-level validation error for the login phone-entry screen.
class PhoneValidationFailure extends ValidationFailure {
  const PhoneValidationFailure(this.fieldErrors)
    : super(message: 'Please fix the highlighted fields.');

  final Map<String, String> fieldErrors;
}

/// Indian mobile numbers: 10 digits starting 6-9, with an optional +91
/// (or bare 91) prefix — the pilot is Bangalore-only.
final _phonePattern = RegExp(r'^(?:\+?91)?[6-9][0-9]{9}$');

/// Validates the phone number entered on the "I already have an account"
/// login flow before requesting an OTP.
class ValidatePhoneNumberUseCase {
  const ValidatePhoneNumberUseCase();

  Result<String> call(String phoneNumber) {
    final phone = phoneNumber.trim().replaceAll(' ', '');

    if (!_phonePattern.hasMatch(phone)) {
      return const Err(
        PhoneValidationFailure({'phoneNumber': 'Enter a valid phone number'}),
      );
    }

    return Ok(phone);
  }
}
