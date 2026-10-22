import '../../../../core/error/result.dart';
import '../entities/host_profile.dart';
import '../repositories/host_profile_repository.dart';

class FetchHostProfileUseCase {
  const FetchHostProfileUseCase(this._repository);

  final HostProfileRepository _repository;

  Future<Result<HostProfile>> call(String userId) => _repository.fetch(userId);
}
