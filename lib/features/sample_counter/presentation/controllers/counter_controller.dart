import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/di/database_providers.dart';
import '../../../../core/di/network_providers.dart';
import '../../data/datasources/counter_local_datasource.dart';
import '../../data/datasources/counter_remote_datasource.dart';
import '../../data/repository_impl/counter_repository_impl.dart';
import '../../domain/entities/counter_record.dart';
import '../../domain/repositories/counter_repository.dart';
import '../../domain/usecases/increment_counter.dart';

part 'counter_controller.g.dart';

@riverpod
CounterLocalDatasource counterLocalDatasource(Ref ref) {
  return DriftCounterLocalDatasource(ref.watch(appDatabaseProvider));
}

@riverpod
CounterRemoteDatasource counterRemoteDatasource(Ref ref) {
  // REST CLIENT (Dio) Remote Datasource by default:
  return CounterRestDatasource(ref.watch(baseApiClientProvider));
  
  // SWAP PATH: To use Firebase, comment the REST client line above and uncomment:
  // return CounterFirebaseDatasource(FirebaseFirestore.instance);
}

@riverpod
CounterRepository counterRepository(Ref ref) {
  return CounterRepositoryImpl(
    ref.watch(counterLocalDatasourceProvider),
    ref.watch(counterRemoteDatasourceProvider),
    ref.watch(appDatabaseProvider),
  );
}

@riverpod
IncrementCounter incrementCounterUseCase(Ref ref) {
  return IncrementCounter(ref.watch(counterRepositoryProvider));
}

@riverpod
class CounterController extends _$CounterController {
  @override
  Future<CounterRecord> build() async {
    final result = await ref.read(counterRepositoryProvider).getCounter();
    return result.when(
      ok: (record) => record,
      err: (failure) => throw failure,
    );
  }

  Future<void> increment() async {
    final currentState = state.value;
    if (currentState == null) return;
    
    state = const AsyncLoading();
    
    final incrementUseCase = ref.read(incrementCounterUseCaseProvider);
    final result = await incrementUseCase(currentState.value);
    
    result.when(
      ok: (record) => state = AsyncData(record),
      err: (Failure failure) => state = AsyncError(failure, StackTrace.current),
    );
  }
}
