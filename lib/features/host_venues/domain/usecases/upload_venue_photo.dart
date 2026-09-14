import '../../../../core/error/result.dart';
import '../entities/host_venue_photo.dart';
import '../repositories/host_venues_repository.dart';

class UploadVenuePhotoUseCase {
  const UploadVenuePhotoUseCase(this._repository);

  final HostVenuesRepository _repository;

  Future<Result<HostVenuePhoto>> call({
    required String filePath,
    required String fileName,
  }) {
    return _repository.uploadVenuePhoto(filePath: filePath, fileName: fileName);
  }
}
