import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_earnings_datasource.dart';
import '../../data/datasources/host_payout_datasource.dart';
import '../../data/repository_impl/host_payout_repository_impl.dart';
import '../../domain/repositories/host_payout_repository.dart';
import '../../domain/usecases/get_host_earnings.dart';
import '../../domain/usecases/get_host_payout.dart';
import '../../domain/usecases/save_host_bank.dart';
import '../../domain/usecases/save_host_upi.dart';

part 'host_payout_providers.g.dart';

/// Kept alive so the in-memory stand-in holds its data for the session.
@Riverpod(keepAlive: true)
HostPayoutDatasource hostPayoutDatasource(Ref ref) {
  return InMemoryHostPayoutDatasource();
}

@riverpod
HostEarningsDatasource hostEarningsDatasource(Ref ref) {
  return HostEarningsRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostPayoutRepository hostPayoutRepository(Ref ref) {
  return HostPayoutRepositoryImpl(
    ref.watch(hostPayoutDatasourceProvider),
    ref.watch(hostEarningsDatasourceProvider),
  );
}

@riverpod
GetHostEarningsUseCase getHostEarningsUseCase(Ref ref) {
  return GetHostEarningsUseCase(ref.watch(hostPayoutRepositoryProvider));
}

@riverpod
GetHostPayoutUseCase getHostPayoutUseCase(Ref ref) {
  return GetHostPayoutUseCase(ref.watch(hostPayoutRepositoryProvider));
}

@riverpod
SaveHostUpiUseCase saveHostUpiUseCase(Ref ref) {
  return SaveHostUpiUseCase(ref.watch(hostPayoutRepositoryProvider));
}

@riverpod
SaveHostBankUseCase saveHostBankUseCase(Ref ref) {
  return SaveHostBankUseCase(ref.watch(hostPayoutRepositoryProvider));
}
