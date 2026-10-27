import '../../../../core/error/result.dart';
import '../entities/host_payout_account.dart';
import '../repositories/host_payout_repository.dart';

class GetHostPayoutUseCase {
  const GetHostPayoutUseCase(this._repository);

  final HostPayoutRepository _repository;

  Future<Result<HostPayoutAccount>> call() => _repository.getPayoutAccount();
}
