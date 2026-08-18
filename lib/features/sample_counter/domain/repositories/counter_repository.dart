import '../../../../core/error/result.dart';
import '../entities/counter_record.dart';

abstract interface class CounterRepository {
  Future<Result<CounterRecord>> getCounter();
  Future<Result<CounterRecord>> updateCounter(int value);
}
