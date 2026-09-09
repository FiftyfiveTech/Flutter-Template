import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/host_signup_draft.dart';

/// Field-level validation errors keyed by [HostSignupDraft] field name
/// (`businessName`, `contactPhone`, `contactEmail`, `city`).
class HostSignupValidationFailure extends ValidationFailure {
  const HostSignupValidationFailure(this.fieldErrors)
    : super(message: 'Please fix the highlighted fields.');

  final Map<String, String> fieldErrors;
}

final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
final _phonePattern = RegExp(r'^\+?[0-9]{10,13}$');

/// Validates the H-01 signup basics: a business/organiser name, contact
/// phone and email, and the operating city. Draft creation is always
/// permitted; this only gates moving past step 1 of the wizard.
class ValidateHostSignupBasicsUseCase {
  const ValidateHostSignupBasicsUseCase();

  Result<HostSignupDraft> call(HostSignupDraft draft) {
    final businessName = draft.businessName.trim();
    final contactPhone = draft.contactPhone.trim().replaceAll(' ', '');
    final contactEmail = draft.contactEmail.trim();
    final city = draft.city.trim();

    final errors = <String, String>{};
    if (businessName.isEmpty) {
      errors['businessName'] = 'Enter a business or organiser name';
    }
    if (!_phonePattern.hasMatch(contactPhone)) {
      errors['contactPhone'] = 'Enter a valid phone number';
    }
    if (!_emailPattern.hasMatch(contactEmail)) {
      errors['contactEmail'] = 'Enter a valid email address';
    }
    if (city.isEmpty || draft.cityId.trim().isEmpty) {
      errors['city'] = 'Select a city';
    }

    if (errors.isNotEmpty) {
      return Err(HostSignupValidationFailure(errors));
    }

    return Ok(
      HostSignupDraft(
        businessName: businessName,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        city: city,
        cityId: draft.cityId.trim(),
      ),
    );
  }
}
