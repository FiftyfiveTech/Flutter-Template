import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_verification_remote_datasource.dart';
import '../../data/repository_impl/host_verification_repository_impl.dart';
import '../../domain/repositories/host_verification_repository.dart';
import '../../domain/usecases/submit_host_verification.dart';

part 'host_verification_api_providers.g.dart';

@riverpod
HostVerificationRemoteDatasource hostVerificationRemoteDatasource(Ref ref) {
  return HostVerificationRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostVerificationRepository hostVerificationRepository(Ref ref) {
  return HostVerificationRepositoryImpl(
    ref.watch(hostVerificationRemoteDatasourceProvider),
  );
}

@riverpod
SubmitHostVerificationUseCase submitHostVerificationUseCase(Ref ref) {
  return SubmitHostVerificationUseCase(
    ref.watch(hostVerificationRepositoryProvider),
  );
}
