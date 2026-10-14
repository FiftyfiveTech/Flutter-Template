import '../../../../core/error/result.dart';
import '../repositories/host_profile_repository.dart';

class ClearHostProfileUseCase {
  const ClearHostProfileUseCase(this._repository);

  final HostProfileRepository _repository;

  Future<Result<void>> call() => _repository.clear();
}
