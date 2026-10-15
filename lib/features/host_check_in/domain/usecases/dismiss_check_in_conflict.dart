import '../../../../core/error/result.dart';
import '../repositories/check_in_repository.dart';

class DismissCheckInConflictUseCase {
  const DismissCheckInConflictUseCase(this._repository);

  final CheckInRepository _repository;

  Future<Result<void>> call(String scanId) =>
      _repository.dismissConflict(scanId);
}
