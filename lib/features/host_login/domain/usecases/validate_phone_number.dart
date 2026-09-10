import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Field-level validation error for the login phone-entry screen.
class PhoneValidationFailure extends ValidationFailure {
  const PhoneValidationFailure(this.fieldErrors)
    : super(message: 'Please fix the highlighted fields.');

  final Map<String, String> fieldErrors;
}

final _phonePattern = RegExp(r'^\+?[0-9]{10,13}$');

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
