import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_home_remote_datasource.dart';
import '../../data/repository_impl/host_home_repository_impl.dart';
import '../../domain/repositories/host_home_repository.dart';
import '../../domain/usecases/get_host_home_summary.dart';

part 'host_home_api_providers.g.dart';

@riverpod
HostHomeRemoteDatasource hostHomeRemoteDatasource(Ref ref) {
  return HostHomeRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostHomeRepository hostHomeRepository(Ref ref) {
  return HostHomeRepositoryImpl(ref.watch(hostHomeRemoteDatasourceProvider));
}

@riverpod
GetHostHomeSummaryUseCase getHostHomeSummaryUseCase(Ref ref) {
  return GetHostHomeSummaryUseCase(ref.watch(hostHomeRepositoryProvider));
}
