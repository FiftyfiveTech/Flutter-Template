import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/document_compressor_providers.dart';
import '../../../../core/files/document_compressor.dart';
import '../../domain/entities/host_document_selection.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_documents_draft.dart';
import '../../domain/entities/host_onboarding_step.dart';
import '../../domain/entities/host_payout_details.dart';
import '../../domain/entities/host_type.dart';
import '../../domain/entities/host_verification_document.dart';
import '../../domain/entities/host_verification_submission_draft.dart';
import '../../domain/usecases/validate_host_documents.dart';
import 'host_document_api_providers.dart';
import 'host_onboarding_progress_controller.dart';
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
/// the duration of this step — [build] seeds it from
/// `HostOnboardingProgressController`'s persisted copy so a restart
/// resumes with the same fields filled and the same documents marked
/// uploaded (any slot that hadn't finished uploading is dropped: there's
/// no local file left to resume it from).
@riverpod
class HostDocumentsController extends _$HostDocumentsController {
  static const _useCase = ValidateHostDocumentsUseCase();

  @override
  HostDocumentsFormState build() {
    final draft =
        ref.read(hostOnboardingProgressControllerProvider)?.documentsDraft ??
        const HostDocumentsDraft();
    final uploadStates = <HostDocumentType, DocumentUploadState>{
      for (final entry in draft.documents.entries)
        if (entry.value.documentId != null)
          entry.key: DocumentUploadState(
            status: DocumentUploadStatus.success,
            documentId: entry.value.documentId,
          ),
    };
    return HostDocumentsFormState(draft: draft, uploadStates: uploadStates);
  }

  void updateUpiId(String value) {
    state = state.copyWith(draft: state.draft.copyWith(upiId: value));
    _persistProgress();
  }

  void setServesFood(bool value) {
    state = state.copyWith(draft: state.draft.copyWith(servesFood: value));
    _persistProgress();
  }

  void setServesAlcohol(bool value) {
    state = state.copyWith(draft: state.draft.copyWith(servesAlcohol: value));
    _persistProgress();
  }

  void updateFssaiLicenceValidFrom(DateTime value) {
    state = state.copyWith(
      draft: state.draft.copyWith(fssaiLicenceValidFrom: value),
    );
    _persistProgress();
  }

  void updateFssaiLicenceValidTo(DateTime value) {
    state = state.copyWith(
      draft: state.draft.copyWith(fssaiLicenceValidTo: value),
    );
    _persistProgress();
  }

  void updateExciseLicenceValidFrom(DateTime value) {
    state = state.copyWith(
      draft: state.draft.copyWith(exciseLicenceValidFrom: value),
    );
    _persistProgress();
  }

  void updateExciseLicenceValidTo(DateTime value) {
    state = state.copyWith(
      draft: state.draft.copyWith(exciseLicenceValidTo: value),
    );
    _persistProgress();
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
      result.when(
        ok: (uploaded) =>
            _onUploadSuccess(type, selection, uploaded.documentId),
        err: (failure) => _setUploadState(
          type,
          DocumentUploadState(
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

  /// Stamps the successful upload's `documentId` onto the draft's
  /// selection too (not just [DocumentUploadState]) — that's the field
  /// `HostOnboardingProgressController` persists, so a resumed session
  /// shows this slot as already uploaded instead of re-asking for it.
  void _onUploadSuccess(
    HostDocumentType type,
    HostDocumentSelection selection,
    String documentId,
  ) {
    final documents =
        Map<HostDocumentType, HostDocumentSelection>.from(state.draft.documents)
          ..[type] = HostDocumentSelection(
            fileName: selection.fileName,
            sizeBytes: selection.sizeBytes,
            documentId: documentId,
          );
    state = state.copyWith(draft: state.draft.copyWith(documents: documents));
    _setUploadState(
      type,
      DocumentUploadState(
        status: DocumentUploadStatus.success,
        documentId: documentId,
      ),
    );
  }

  void _setUploadState(HostDocumentType type, DocumentUploadState value) {
    final uploadStates = Map<HostDocumentType, DocumentUploadState>.from(
      state.uploadStates,
    )..[type] = value;
    state = state.copyWith(uploadStates: uploadStates);
    _persistProgress();
  }

  /// Persists [state.draft] via `HostOnboardingProgressController`,
  /// dropping any document slot that hasn't finished uploading — there's
  /// no local file behind it to resume from, and a stale "selected but
  /// not uploaded" row would just confuse a resumed session.
  void _persistProgress() {
    final persistable = state.draft.copyWith(
      documents: {
        for (final entry in state.draft.documents.entries)
          if (entry.value.documentId != null) entry.key: entry.value,
      },
    );
    ref
        .read(hostOnboardingProgressControllerProvider.notifier)
        .updateDocumentsDraft(persistable);
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
      ok: (_) {
        state = state.copyWith(isSubmitting: false);
        ref
            .read(hostOnboardingProgressControllerProvider.notifier)
            .setStep(HostOnboardingStep.verification);
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
