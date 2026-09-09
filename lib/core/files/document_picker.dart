import 'package:file_picker/file_picker.dart';

/// Metadata for a locally picked file, plus its on-disk [path] so the
/// upload call can read it fresh and compress/discard it immediately —
/// see `HostDocumentSelection`'s doc comment: the path is used transiently
/// for upload, never persisted into a stored entity.
class DocumentPickerResult {
  const DocumentPickerResult({
    required this.fileName,
    required this.path,
    this.sizeBytes,
  });

  final String fileName;
  final String path;
  final int? sizeBytes;
}

/// Thin seam over the `file_picker` plugin so presentation code depends on
/// an interface (swappable via `ProviderScope(overrides: [...])` in tests)
/// instead of calling the static plugin API directly.
abstract class DocumentPicker {
  Future<DocumentPickerResult?> pickFile({
    required List<String> allowedExtensions,
  });
}

class FilePickerDocumentPicker implements DocumentPicker {
  const FilePickerDocumentPicker();

  @override
  Future<DocumentPickerResult?> pickFile({
    required List<String> allowedExtensions,
  }) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (file == null || file.path == null) return null;
    return DocumentPickerResult(
      fileName: file.name,
      path: file.path!,
      sizeBytes: file.lengthSync(),
    );
  }
}
