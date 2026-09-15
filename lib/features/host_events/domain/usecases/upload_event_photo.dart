import '../../../../core/error/result.dart';
import '../entities/host_event_photo.dart';
import '../repositories/host_events_repository.dart';

class UploadEventPhotoUseCase {
  const UploadEventPhotoUseCase(this._repository);

  final HostEventsRepository _repository;

  Future<Result<HostEventPhoto>> call({
    required String filePath,
    required String fileName,
  }) {
    return _repository.uploadEventPhoto(filePath: filePath, fileName: fileName);
  }
}
