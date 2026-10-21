import '../../../../core/error/result.dart';
import '../repositories/host_profile_repository.dart';

class DeleteHostAccountUseCase {
  const DeleteHostAccountUseCase(this._repository);

  final HostProfileRepository _repository;

  Future<Result<void>> call() => _repository.deleteAccount();
}
