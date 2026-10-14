import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _avatarDirName = 'profile';
const _avatarMaxSide = 512;

/// Keeps the host's avatar as a downscaled JPEG in the app's private
/// documents directory, so it's available offline and survives restarts
/// (the picker's own path may be a temp/cache file the OS can purge).
abstract interface class HostProfilePhotoStore {
  /// Stores a copy of [sourcePath] and returns the stored file's path.
  Future<String> store(String sourcePath);
  Future<void> delete(String? path);
}

class FileHostProfilePhotoStore implements HostProfilePhotoStore {
  const FileHostProfilePhotoStore();

  @override
  Future<String> store(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _avatarDirName));
    await dir.create(recursive: true);
    // A fresh name per pick, so `Image.file`'s cache never shows the old
    // avatar for a path that's been overwritten.
    final target = p.join(
      dir.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      target,
      minWidth: _avatarMaxSide,
      minHeight: _avatarMaxSide,
      quality: 85,
    );
    if (compressed != null) return compressed.path;
    return (await File(sourcePath).copy(target)).path;
  }

  @override
  Future<void> delete(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
