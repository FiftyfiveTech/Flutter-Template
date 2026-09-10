import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_login_remote_datasource.dart';
import '../../data/repository_impl/host_login_repository_impl.dart';
import '../../domain/repositories/host_login_repository.dart';
import '../../domain/usecases/request_otp.dart';
import '../../domain/usecases/verify_otp.dart';

part 'host_login_api_providers.g.dart';

@riverpod
HostLoginRemoteDatasource hostLoginRemoteDatasource(Ref ref) {
  return HostLoginRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostLoginRepository hostLoginRepository(Ref ref) {
  return HostLoginRepositoryImpl(ref.watch(hostLoginRemoteDatasourceProvider));
}

@riverpod
RequestOtpUseCase requestOtpUseCase(Ref ref) {
  return RequestOtpUseCase(ref.watch(hostLoginRepositoryProvider));
}

@riverpod
VerifyOtpUseCase verifyOtpUseCase(Ref ref) {
  return VerifyOtpUseCase(ref.watch(hostLoginRepositoryProvider));
}
