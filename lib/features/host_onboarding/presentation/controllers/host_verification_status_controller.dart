import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/host_document_status.dart';
import '../../domain/entities/host_document_verification_status.dart';
import 'host_document_status_api_providers.dart';

part 'host_verification_status_controller.g.dart';

/// Fetches document review status for H-04 · Verification on load and on
/// pull-to-refresh. Screen-scoped (autoDispose): only needs to live while
/// the status screen is on-screen.
@riverpod
class HostVerificationStatusController
    extends _$HostVerificationStatusController {
  @override
  Future<List<HostDocumentStatus>> build() {
    return _fetch();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<List<HostDocumentStatus>> _fetch() async {
    final useCase = ref.read(getHostDocumentsStatusUseCaseProvider);
    final result = await useCase();
    return result.when(
      ok: (documents) => documents,
      err: (failure) => throw StateError(failure.message),
    );
  }
}

extension HostDocumentStatusListX on List<HostDocumentStatus> {
  bool get allVerified =>
      isNotEmpty &&
      every((doc) => doc.status == HostDocumentVerificationStatus.approved);
}
