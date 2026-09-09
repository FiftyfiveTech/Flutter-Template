import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_signup_remote_datasource.dart';
import '../../data/repository_impl/host_signup_repository_impl.dart';
import '../../domain/repositories/host_signup_repository.dart';
import '../../domain/usecases/signup_host.dart';

part 'host_signup_api_providers.g.dart';

@riverpod
HostSignupRemoteDatasource hostSignupRemoteDatasource(Ref ref) {
  return HostSignupRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostSignupRepository hostSignupRepository(Ref ref) {
  return HostSignupRepositoryImpl(
    ref.watch(hostSignupRemoteDatasourceProvider),
  );
}

@riverpod
SignupHostUseCase signupHostUseCase(Ref ref) {
  return SignupHostUseCase(ref.watch(hostSignupRepositoryProvider));
}
