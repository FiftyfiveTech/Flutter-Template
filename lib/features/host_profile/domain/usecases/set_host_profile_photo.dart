import '../../../../core/error/result.dart';
import '../repositories/host_profile_repository.dart';

class SetHostProfilePhotoUseCase {
  const SetHostProfilePhotoUseCase(this._repository);

  final HostProfileRepository _repository;

  Future<Result<String>> call(String userId, String sourcePath) =>
      _repository.setPhoto(userId, sourcePath);
}
