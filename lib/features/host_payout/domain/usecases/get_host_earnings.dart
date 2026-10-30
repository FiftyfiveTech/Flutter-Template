import '../../../../core/error/result.dart';
import '../entities/host_earnings.dart';
import '../repositories/host_payout_repository.dart';

class GetHostEarningsUseCase {
  const GetHostEarningsUseCase(this._repository);

  final HostPayoutRepository _repository;

  Future<Result<HostEarnings>> call() => _repository.getEarnings();
}
