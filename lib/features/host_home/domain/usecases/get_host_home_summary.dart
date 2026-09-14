import '../../../../core/error/result.dart';
import '../entities/host_home_summary.dart';
import '../repositories/host_home_repository.dart';

class GetHostHomeSummaryUseCase {
  const GetHostHomeSummaryUseCase(this._repository);

  final HostHomeRepository _repository;

  Future<Result<HostHomeSummary>> call() => _repository.getHomeSummary();
}
