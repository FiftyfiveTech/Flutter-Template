import '../../../../core/error/result.dart';
import '../entities/host_profile.dart';
import '../repositories/host_profile_repository.dart';

class CacheHostProfileUseCase {
  const CacheHostProfileUseCase(this._repository);

  final HostProfileRepository _repository;

  Future<Result<void>> call(HostProfile profile) => _repository.cache(profile);
}
