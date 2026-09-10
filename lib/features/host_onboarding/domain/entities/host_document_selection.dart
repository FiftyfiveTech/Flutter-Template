/// A locally picked file's metadata for one document slot, plus the
/// server-assigned id once it's finished uploading. Deliberately holds
/// no raw bytes/path — only what's needed to show the user what they
/// picked, and what's safe to persist across a restart (H-03's progress
/// is saved to `HostOnboardingProgressTable` keyed by this id, never by
/// the local file). The upload call reads the file fresh from the
/// picker result and discards it immediately after, never routing raw
/// bytes through this entity (`docs/features/02-identity-verification.md`
/// §4's "raw ID images are never persisted" applies equally to host
/// documents).
class HostDocumentSelection {
  const HostDocumentSelection({
    required this.fileName,
    this.sizeBytes,
    this.documentId,
  });

  final String fileName;
  final int? sizeBytes;

  /// Set once the upload behind this slot succeeds — the `documentId`
  /// `HostDocumentUploadResult` returned. `null` means the pick either
  /// hasn't finished uploading yet or failed; such entries are never
  /// persisted (there'd be nothing valid to resume into).
  final String? documentId;
}
