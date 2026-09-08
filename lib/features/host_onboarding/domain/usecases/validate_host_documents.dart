import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/host_document_type.dart';
import '../entities/host_documents_draft.dart';
import '../entities/host_type.dart';

/// Field-level validation errors keyed by [HostDocumentsDraft] field name,
/// or by [HostDocumentType.name] for a missing required document.
class HostDocumentsValidationFailure extends ValidationFailure {
  const HostDocumentsValidationFailure(this.fieldErrors)
    : super(message: 'Please fix the highlighted fields.');

  final Map<String, String> fieldErrors;
}

final _upiPattern = RegExp(r'^[\w.\-]{2,}@[A-Za-z]{2,}$');

/// Validates the H-03 documents step. Which documents are required, and
/// whether the excise licence validity window applies, both depend on
/// `hostType` (and, for food/alcohol, the draft's own declarations) —
/// `host-app/01-host-onboarding.md` §4: document requirements are strictly
/// conditional on `host_type`, never a flat set.
class ValidateHostDocumentsUseCase {
  const ValidateHostDocumentsUseCase();

  Result<HostDocumentsDraft> call(
    HostDocumentsDraft draft, {
    required HostType hostType,
  }) {
    final upiId = draft.upiId.trim();
    final errors = <String, String>{};

    if (!_upiPattern.hasMatch(upiId)) {
      errors['upiId'] = 'Enter a valid UPI ID';
    }

    for (final type in _requiredDocuments(hostType, draft)) {
      if (!draft.documents.containsKey(type)) {
        errors[type.name] = 'Upload required';
      }
    }

    if (hostType == HostType.venue && draft.servesAlcohol) {
      if (draft.licenceValidFrom == null) {
        errors['licenceValidFrom'] = 'Required when serving alcohol';
      }
      if (draft.licenceValidTo == null) {
        errors['licenceValidTo'] = 'Required when serving alcohol';
      } else if (draft.licenceValidFrom != null &&
          !draft.licenceValidTo!.isAfter(draft.licenceValidFrom!)) {
        errors['licenceValidTo'] = 'Must be after the start date';
      }
    }

    if (errors.isNotEmpty) {
      return Err(HostDocumentsValidationFailure(errors));
    }

    return Ok(draft.copyWith(upiId: upiId));
  }

  List<HostDocumentType> _requiredDocuments(
    HostType hostType,
    HostDocumentsDraft draft,
  ) {
    final required = [
      HostDocumentType.businessRegistration,
      HostDocumentType.panCard,
    ];
    if (hostType != HostType.venue) return required;

    required.add(HostDocumentType.addressProof);
    if (draft.servesFood) required.add(HostDocumentType.fssaiRegistration);
    if (draft.servesAlcohol) required.add(HostDocumentType.exciseLicence);
    return required;
  }
}
