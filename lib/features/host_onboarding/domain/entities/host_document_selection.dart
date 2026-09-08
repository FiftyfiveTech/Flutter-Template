/// A locally picked file's metadata for one document slot. Deliberately
/// holds no raw bytes/path — only what's needed to show the user what
/// they picked. There is no backend yet to upload to; once one exists,
/// the upload call should read the file fresh from the picker result and
/// discard it immediately after, never routing raw bytes through this
/// entity (`docs/features/02-identity-verification.md` §4's "raw ID
/// images are never persisted" applies equally to host documents).
class HostDocumentSelection {
  const HostDocumentSelection({required this.fileName, this.sizeBytes});

  final String fileName;
  final int? sizeBytes;
}
