import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/document_compressor_providers.dart';
import '../../../../core/files/document_compressor.dart';
import '../../domain/entities/host_document_selection.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_documents_draft.dart';
import '../../domain/entities/host_type.dart';
import '../../domain/usecases/validate_host_documents.dart';
import 'host_document_api_providers.dart';

part 'host_documents_controller.g.dart';

enum DocumentUploadStatus { uploading, success, error }

/// Background upload progress for one document slot, tracked separately
/// from the draft so a slow/failed upload never blocks the user from
/// picking other documents or moving through the rest of the form.
class DocumentUploadState {
  const DocumentUploadState({required this.status, this.errorMessage});

  final DocumentUploadStatus status;
  final String? errorMessage;
}

class HostDocumentsFormState {
  const HostDocumentsFormState({
    this.draft = const HostDocumentsDraft(),
    this.fieldErrors = const {},
    this.uploadStates = const {},
  });

  final HostDocumentsDraft draft;

  /// Keyed by `HostDocumentType.name` (matching the field-validation keys),
  /// so upload problems render in the exact same place as validation
  /// errors — right below that document's row — once [submit] runs.
  final Map<String, String> fieldErrors;
  final Map<HostDocumentType, DocumentUploadState> uploadStates;

  HostDocumentsFormState copyWith({
    HostDocumentsDraft? draft,
    Map<String, String>? fieldErrors,
    Map<HostDocumentType, DocumentUploadState>? uploadStates,
  }) {
    return HostDocumentsFormState(
      draft: draft ?? this.draft,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      uploadStates: uploadStates ?? this.uploadStates,
    );
  }
}

/// Holds the H-03 documents form draft, validates it on submit, and
/// silently uploads each document in the background as soon as it's
/// picked so the user can keep filling the rest of the form without
/// waiting. Screen-scoped (autoDispose): the draft only needs to live for
/// the duration of this step.
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

  /// Records the pick immediately (so the row shows the file name) and
  /// kicks off compression + upload in the background. Callers don't
  /// await this beyond the initial state update — errors surface later
  /// via [HostDocumentsFormState.uploadStates] instead of a thrown
  /// exception, since by the time they land the user has likely moved on.
  void selectDocument(
    HostDocumentType type,
    HostDocumentSelection selection,
    String filePath,
  ) {
    final documents = Map<HostDocumentType, HostDocumentSelection>.from(
      state.draft.documents,
    )..[type] = selection;
    final uploadStates =
        Map<HostDocumentType, DocumentUploadState>.from(state.uploadStates)
          ..[type] = const DocumentUploadState(
            status: DocumentUploadStatus.uploading,
          );
    state = state.copyWith(
      draft: state.draft.copyWith(documents: documents),
      uploadStates: uploadStates,
    );
    unawaited(_uploadInBackground(type, selection, filePath));
  }

  Future<void> _uploadInBackground(
    HostDocumentType type,
    HostDocumentSelection selection,
    String filePath,
  ) async {
    try {
      final compressor = ref.read(documentCompressorProvider);
      final uploadPath = await compressor.compress(
        filePath,
        selection.fileName,
      );
      final useCase = ref.read(uploadHostDocumentUseCaseProvider);
      final result = await useCase(
        documentType: type,
        filePath: uploadPath,
        fileName: selection.fileName,
      );
      // A newer pick for this slot may have started (and thus overwritten
      // this entry) while the upload was in flight — don't let a stale
      // result clobber it.
      if (state.draft.documents[type] != selection) return;
      _setUploadState(
        type,
        result.when(
          ok: (_) =>
              const DocumentUploadState(status: DocumentUploadStatus.success),
          err: (failure) => DocumentUploadState(
            status: DocumentUploadStatus.error,
            errorMessage: failure.message,
          ),
        ),
      );
    } on DocumentTooLargeException catch (e) {
      if (state.draft.documents[type] != selection) return;
      _setUploadState(
        type,
        DocumentUploadState(
          status: DocumentUploadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    } catch (_) {
      if (state.draft.documents[type] != selection) return;
      _setUploadState(
        type,
        const DocumentUploadState(
          status: DocumentUploadStatus.error,
          errorMessage: "Couldn't be uploaded",
        ),
      );
    }
  }

  void _setUploadState(HostDocumentType type, DocumentUploadState value) {
    final uploadStates =
        Map<HostDocumentType, DocumentUploadState>.from(state.uploadStates)
          ..[type] = value;
    state = state.copyWith(uploadStates: uploadStates);
  }

  /// Validates the draft against [hostType]'s document set, then checks
  /// every selected document has finished uploading successfully. Returns
  /// true only when both pass, so the wizard can advance to H-04 ·
  /// Verification. Problems from both checks land in the same
  /// [HostDocumentsFormState.fieldErrors] map, so they render right below
  /// the field they belong to instead of in a separate summary.
  bool submit({required HostType hostType}) {
    final result = _useCase(state.draft, hostType: hostType);
    return result.when(
      ok: (validated) {
        final fieldErrors = _collectUploadFieldErrors(validated);
        state = state.copyWith(draft: validated, fieldErrors: fieldErrors);
        return fieldErrors.isEmpty;
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

  Map<String, String> _collectUploadFieldErrors(HostDocumentsDraft draft) {
    final errors = <String, String>{};
    for (final type in draft.documents.keys) {
      final uploadState = state.uploadStates[type];
      if (uploadState == null) continue;
      switch (uploadState.status) {
        case DocumentUploadStatus.uploading:
          errors[type.name] = 'Still uploading — please wait';
        case DocumentUploadStatus.error:
          errors[type.name] = uploadState.errorMessage ?? 'Failed to upload';
        case DocumentUploadStatus.success:
          break;
      }
    }
    return errors;
  }
}
