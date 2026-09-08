import 'package:file_picker/file_picker.dart';

/// Metadata for a locally picked file — deliberately no raw bytes/path,
/// see `HostDocumentSelection`'s doc comment for why.
class DocumentPickerResult {
  const DocumentPickerResult({required this.fileName, this.sizeBytes});

  final String fileName;
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
    if (file == null) return null;
    return DocumentPickerResult(
      fileName: file.name,
      sizeBytes: file.lengthSync(),
    );
  }
}
