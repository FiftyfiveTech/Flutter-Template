import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/di/document_compressor_providers.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/files/document_compressor.dart';
import 'package:host_mobile_app/features/host_venues/domain/entities/host_venue_photo.dart';
import 'package:host_mobile_app/features/host_venues/domain/usecases/upload_venue_photo.dart';
import 'package:host_mobile_app/features/host_venues/presentation/controllers/host_venue_form_controller.dart';
import 'package:host_mobile_app/features/host_venues/presentation/controllers/host_venues_api_providers.dart';
import 'package:host_mobile_app/shared/widgets/ah_photo_slots.dart';

class _PassThroughCompressor implements DocumentCompressor {
  @override
  Future<String> compress(String path, String fileName) async => path;
}

/// Holds every upload open until the test completes it by file path.
class _ControlledUpload implements UploadVenuePhotoUseCase {
  final pending = <String, Completer<Result<HostVenuePhoto>>>{};

  @override
  Future<Result<HostVenuePhoto>> call({
    required String filePath,
    required String fileName,
  }) {
    return (pending[filePath] = Completer()).future;
  }

  Future<void> finish(String filePath) async {
    pending[filePath]!.complete(
      Ok(HostVenuePhoto(id: filePath, url: 'https://cdn/$filePath')),
    );
    await pumpEventQueue();
  }
}

void main() {
  late _ControlledUpload upload;
  late ProviderContainer container;
  final provider = hostVenueFormControllerProvider(null);

  HostVenueFormController controller() => container.read(provider.notifier);
  HostVenueFormState state() => container.read(provider);

  Future<void> pick(int index, String path) async {
    controller().pickPhotoAt(index, path, '$path.jpg');
    await pumpEventQueue();
  }

  setUp(() {
    upload = _ControlledUpload();
    container = ProviderContainer(
      overrides: [
        uploadVenuePhotoUseCaseProvider.overrideWithValue(upload),
        documentCompressorProvider.overrideWithValue(_PassThroughCompressor()),
      ],
    );
    container.listen(provider, (_, _) {});
  });
  tearDown(() => container.dispose());

  test('removing a photo shifts later photos down a slot', () async {
    for (final (i, path) in ['a', 'b', 'c'].indexed) {
      await pick(i, path);
      await upload.finish(path);
    }

    controller().removePhotoAt(0);

    expect(state().photoSlots.map((s) => s.localPath), ['b', 'c']);
    expect(state().draft.photos.map((p) => p.id), ['b', 'c']);
  });

  test('an in-flight upload lands on its shifted slot', () async {
    await pick(0, 'a');
    await upload.finish('a');
    await pick(1, 'b');

    controller().removePhotoAt(0);
    await upload.finish('b');

    expect(state().photoSlots.single.status, AhPhotoSlotStatus.uploaded);
    expect(state().draft.photos.single.id, 'b');
  });

  test("a removed photo's upload is dropped when it completes", () async {
    await pick(0, 'a');

    controller().removePhotoAt(0);
    await upload.finish('a');

    expect(state().photoSlots, isEmpty);
    expect(state().draft.photos, isEmpty);
  });
}
