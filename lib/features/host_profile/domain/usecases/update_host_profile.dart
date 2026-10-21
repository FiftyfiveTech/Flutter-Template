import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/host_profile.dart';
import '../entities/host_profile_edit.dart';
import '../repositories/host_profile_repository.dart';

/// Field-level errors keyed by [HostProfileEdit] field name (`firstName`,
/// `lastName`, `businessName`) — from client-side checks or the server's
/// `VALIDATION_FAILED` response.
class HostProfileValidationFailure extends ValidationFailure {
  const HostProfileValidationFailure(
    this.fieldErrors, {
    super.message = 'Please fix the highlighted fields.',
  });

  final Map<String, String> fieldErrors;
}

/// Limits from the API's `UpdateHostProfileDto`.
const hostNameMaxLength = 50;
const hostBusinessNameMaxLength = 200;

/// Validates and saves an Edit profile change. Fields are trimmed; the
/// server rejects empty strings (`minLength: 1`), so a blank field fails
/// here rather than silently clearing the stored value.
class UpdateHostProfileUseCase {
  const UpdateHostProfileUseCase(this._repository);

  final HostProfileRepository _repository;

  Future<Result<HostProfile>> call(String userId, HostProfileEdit edit) async {
    final firstName = edit.firstName?.trim();
    final lastName = edit.lastName?.trim();
    final businessName = edit.businessName?.trim();

    final errors = <String, String>{};
    final firstNameError = _lengthError(
      firstName,
      'Enter a first name',
      hostNameMaxLength,
    );
    if (firstNameError != null) errors['firstName'] = firstNameError;
    final lastNameError = _lengthError(
      lastName,
      'Enter a last name',
      hostNameMaxLength,
    );
    if (lastNameError != null) errors['lastName'] = lastNameError;
    final businessNameError = _lengthError(
      businessName,
      'Enter a business or organiser name',
      hostBusinessNameMaxLength,
    );
    if (businessNameError != null) errors['businessName'] = businessNameError;

    if (errors.isNotEmpty) return Err(HostProfileValidationFailure(errors));

    return _repository.update(
      userId,
      HostProfileEdit(
        firstName: firstName,
        lastName: lastName,
        businessName: businessName,
        photoSourcePath: edit.photoSourcePath,
      ),
    );
  }

  String? _lengthError(String? value, String emptyMessage, int maxLength) {
    if (value == null) return null;
    if (value.isEmpty) return emptyMessage;
    if (value.length > maxLength) {
      return 'Use $maxLength characters or fewer';
    }
    return null;
  }
}
