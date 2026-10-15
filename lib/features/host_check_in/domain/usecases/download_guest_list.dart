import '../../../../core/error/result.dart';
import '../entities/check_in_manifest.dart';
import '../repositories/check_in_repository.dart';

/// Downloads a fresh offline guest list. Run when the door opens and
/// whenever the cached one is close to (or past) its expiry.
class DownloadGuestListUseCase {
  const DownloadGuestListUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<CheckInManifest>> call(String eventId) =>
      _repository.downloadManifest(eventId);
}
