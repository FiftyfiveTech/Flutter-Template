import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/counter_record.dart';
import '../repositories/counter_repository.dart';

class IncrementCounter {
  const IncrementCounter(this._repository);
  final CounterRepository _repository;

  Future<Result<CounterRecord>> call(int currentCount) async {
    if (currentCount >= 100) {
      return const Err(ValidationFailure(message: 'Counter cannot exceed 100.'));
    }
    return _repository.updateCounter(currentCount + 1);
  }
}
