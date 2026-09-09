import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _maxUploadBytes = 5 * 1024 * 1024;
const _compressibleExtensions = {'.jpg', '.jpeg', '.png'};

/// Thrown when a file can't be brought under the 5 MB upload limit —
/// either compression couldn't shrink it enough, or the format (e.g. PDF)
/// can't be compressed client-side at all.
class DocumentTooLargeException implements Exception {
  DocumentTooLargeException(this.fileName);
  final String fileName;

  @override
  String toString() => '$fileName is too large — please use a file under 5MB';
}

/// Shrinks a locally picked file to under 5MB before it's uploaded.
/// Images (jpg/jpeg/png) are re-encoded at decreasing quality until they
/// fit; other formats (e.g. PDF) can't be compressed here, so a file
/// already under the limit passes through and an oversized one throws
/// [DocumentTooLargeException].
abstract class DocumentCompressor {
  Future<String> compress(String path, String fileName);
}

class ImageDocumentCompressor implements DocumentCompressor {
  const ImageDocumentCompressor();

  @override
  Future<String> compress(String path, String fileName) async {
    final file = File(path);
    final originalSize = await file.length();
    if (originalSize <= _maxUploadBytes) return path;

    final extension = p.extension(path).toLowerCase();
    if (!_compressibleExtensions.contains(extension)) {
      throw DocumentTooLargeException(fileName);
    }

    final tempDir = await getTemporaryDirectory();
    var quality = 85;
    for (var attempt = 0; attempt < 5; attempt++) {
      final targetPath = p.join(
        tempDir.path,
        '${p.basenameWithoutExtension(path)}_$attempt$extension',
      );
      final compressed = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: quality,
        format: extension == '.png' ? CompressFormat.png : CompressFormat.jpeg,
      );
      if (compressed == null) break;
      final compressedSize = await File(compressed.path).length();
      if (compressedSize <= _maxUploadBytes) return compressed.path;
      quality -= 20;
      if (quality <= 20) break;
    }
    throw DocumentTooLargeException(fileName);
  }
}
