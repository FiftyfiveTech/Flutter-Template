import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/host_document_selection.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_documents_draft.dart';
import '../../domain/entities/host_type.dart';
import '../../domain/usecases/validate_host_documents.dart';

part 'host_documents_controller.g.dart';

class HostDocumentsFormState {
  const HostDocumentsFormState({
    this.draft = const HostDocumentsDraft(),
    this.fieldErrors = const {},
  });

  final HostDocumentsDraft draft;
  final Map<String, String> fieldErrors;

  HostDocumentsFormState copyWith({
    HostDocumentsDraft? draft,
    Map<String, String>? fieldErrors,
  }) {
    return HostDocumentsFormState(
      draft: draft ?? this.draft,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

/// Holds the H-03 documents form draft and validates it on submit.
/// Screen-scoped (autoDispose): the draft only needs to live for the
/// duration of this step.
@riverpod
class HostDocumentsController extends _$HostDocumentsController {
  static const _useCase = ValidateHostDocumentsUseCase();

  @override
  HostDocumentsFormState build() => const HostDocumentsFormState();

  void updateUpiId(String value) {
    state = state.copyWith(draft: state.draft.copyWith(upiId: value));
  }

  void setServesFood(bool value) {
    state = state.copyWith(draft: state.draft.copyWith(servesFood: value));
  }

  void setServesAlcohol(bool value) {
    state = state.copyWith(draft: state.draft.copyWith(servesAlcohol: value));
  }

  void updateFssaiLicenceValidFrom(DateTime value) {
    state = state.copyWith(
      draft: state.draft.copyWith(fssaiLicenceValidFrom: value),
    );
  }

  void updateFssaiLicenceValidTo(DateTime value) {
    state = state.copyWith(
      draft: state.draft.copyWith(fssaiLicenceValidTo: value),
    );
  }

  void updateExciseLicenceValidFrom(DateTime value) {
    state = state.copyWith(
      draft: state.draft.copyWith(exciseLicenceValidFrom: value),
    );
  }

  void updateExciseLicenceValidTo(DateTime value) {
    state = state.copyWith(
      draft: state.draft.copyWith(exciseLicenceValidTo: value),
    );
  }

  void selectDocument(HostDocumentType type, HostDocumentSelection selection) {
    final documents = Map<HostDocumentType, HostDocumentSelection>.from(
      state.draft.documents,
    )..[type] = selection;
    state = state.copyWith(draft: state.draft.copyWith(documents: documents));
  }

  /// Validates the draft against [hostType]'s document set. Returns true
  /// (and clears field errors) when the step is complete and the wizard
  /// can advance to H-04 · Verification.
  bool submit({required HostType hostType}) {
    final result = _useCase(state.draft, hostType: hostType);
    return result.when(
      ok: (validated) {
        state = state.copyWith(draft: validated, fieldErrors: const {});
        return true;
      },
      err: (failure) {
        final fieldErrors = failure is HostDocumentsValidationFailure
            ? failure.fieldErrors
            : const <String, String>{};
        state = state.copyWith(fieldErrors: fieldErrors);
        return false;
      },
    );
  }
}
