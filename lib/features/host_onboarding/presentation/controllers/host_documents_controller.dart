import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/document_compressor_providers.dart';
import '../../../../core/di/session_providers.dart';
import '../../../../core/files/document_compressor.dart';
import '../../../../core/session/host_session.dart';
import '../../domain/entities/host_document_selection.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_documents_draft.dart';
import '../../domain/entities/host_payout_details.dart';
import '../../domain/entities/host_type.dart';
import '../../domain/entities/host_verification_document.dart';
import '../../domain/entities/host_verification_submission_draft.dart';
import '../../domain/usecases/validate_host_documents.dart';
import 'host_document_api_providers.dart';
import 'host_verification_api_providers.dart';

part 'host_documents_controller.g.dart';

enum DocumentUploadStatus { uploading, success, error }

/// Background upload progress for one document slot, tracked separately
/// from the draft so a slow/failed upload never blocks the user from
/// picking other documents or moving through the rest of the form.
class DocumentUploadState {
  const DocumentUploadState({
    required this.status,
    this.errorMessage,
    this.documentId,
  });

  final DocumentUploadStatus status;
  final String? errorMessage;

  /// The uploaded document's id, set once [status] is
  /// [DocumentUploadStatus.success] — the `uploadId` submit-verification
  /// needs for this slot.
  final String? documentId;
}

class HostDocumentsFormState {
  const HostDocumentsFormState({
    this.draft = const HostDocumentsDraft(),
    this.fieldErrors = const {},
    this.uploadStates = const {},
    this.isSubmitting = false,
    this.submitError,
  });

  final HostDocumentsDraft draft;

  /// Keyed by `HostDocumentType.name` (matching the field-validation keys),
  /// so upload problems render in the exact same place as validation
  /// errors — right below that document's row — once [submit] runs.
  final Map<String, String> fieldErrors;
  final Map<HostDocumentType, DocumentUploadState> uploadStates;

  /// True while [submitForReview]'s API call is in flight.
  final bool isSubmitting;

  /// Set when the submit-verification API call itself fails
  /// (network/server), as opposed to [fieldErrors] from client-side
  /// validation.
  final String? submitError;

  HostDocumentsFormState copyWith({
    HostDocumentsDraft? draft,
    Map<String, String>? fieldErrors,
    Map<HostDocumentType, DocumentUploadState>? uploadStates,
    bool? isSubmitting,
    String? submitError,
  }) {
    return HostDocumentsFormState(
      draft: draft ?? this.draft,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      uploadStates: uploadStates ?? this.uploadStates,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
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
          ok: (uploaded) => DocumentUploadState(
            status: DocumentUploadStatus.success,
            documentId: uploaded.documentId,
          ),
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
    final uploadStates = Map<HostDocumentType, DocumentUploadState>.from(
      state.uploadStates,
    )..[type] = value;
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

  /// Assembles the validated draft's documents/payout details and submits
  /// them for review. Only call after [submit] has returned true, so every
  /// selected document already carries a successful upload's
  /// [DocumentUploadState.documentId]. Returns true once the account moves
  /// into review and the wizard can advance to H-04 · Verification; on an
  /// API failure, [HostDocumentsFormState.submitError] is set instead.
  Future<bool> submitForReview({required HostType hostType}) async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    final draft = state.draft;
    final documents = draft.documents.entries.map((entry) {
      final type = entry.key;
      final isFssai = type == HostDocumentType.fssaiRegistration;
      final isExcise = type == HostDocumentType.exciseLicence;
      return HostVerificationDocument(
        docType: type,
        uploadId: state.uploadStates[type]?.documentId ?? '',
        issuedAt: isFssai
            ? draft.fssaiLicenceValidFrom
            : isExcise
            ? draft.exciseLicenceValidFrom
            : null,
        expiresAt: isFssai
            ? draft.fssaiLicenceValidTo
            : isExcise
            ? draft.exciseLicenceValidTo
            : null,
      );
    }).toList();

    final submissionDraft = HostVerificationSubmissionDraft(
      hostType: hostType,
      servesFood: draft.servesFood,
      servesAlcohol: draft.servesAlcohol,
      payoutDetails: HostPayoutDetails(
        method: HostPayoutMethod.upi,
        vpa: draft.upiId,
      ),
      documents: documents,
    );

    final useCase = ref.read(submitHostVerificationUseCaseProvider);
    final result = await useCase(submissionDraft);
    return result.when(
      ok: (verification) {
        final session = ref.read(hostSessionControllerProvider);
        if (session != null) {
          ref
              .read(hostSessionControllerProvider.notifier)
              .setSession(
                HostSession(
                  accessToken: session.accessToken,
                  userId: session.userId,
                  accountStatus: verification.accountStatus,
                ),
              );
        }
        state = state.copyWith(isSubmitting: false);
        return true;
      },
      err: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: failure.message,
        );
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
