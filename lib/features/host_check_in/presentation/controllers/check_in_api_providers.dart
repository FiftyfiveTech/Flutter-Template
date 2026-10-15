import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/database_providers.dart';
import '../../../../core/di/network_providers.dart';
import '../../data/datasources/check_in_local_datasource.dart';
import '../../data/datasources/check_in_remote_datasource.dart';
import '../../data/repository_impl/check_in_repository_impl.dart';
import '../../data/services/check_in_id_generator.dart';
import '../../data/services/sha256_qr_hasher.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../../domain/services/qr_hasher.dart';
import '../../domain/usecases/check_in_ticket.dart';
import '../../domain/usecases/dismiss_check_in_conflict.dart';
import '../../domain/usecases/download_guest_list.dart';
import '../../domain/usecases/get_check_in_sync_status.dart';
import '../../domain/usecases/get_guest_list.dart';
import '../../domain/usecases/manual_check_in.dart';
import '../../domain/usecases/queue_unverified_check_in.dart';
import '../../domain/usecases/sync_all_pending_check_ins.dart';
import '../../domain/usecases/sync_pending_check_ins.dart';

part 'check_in_api_providers.g.dart';

@riverpod
CheckInRemoteDatasource checkInRemoteDatasource(Ref ref) {
  return CheckInRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
CheckInLocalDatasource checkInLocalDatasource(Ref ref) {
  return DriftCheckInLocalDatasource(ref.watch(appDatabaseProvider));
}

@riverpod
QrHasher qrHasher(Ref ref) => const Sha256QrHasher();

@riverpod
CheckInRepository checkInRepository(Ref ref) {
  return CheckInRepositoryImpl(
    ref.watch(checkInRemoteDatasourceProvider),
    ref.watch(checkInLocalDatasourceProvider),
    CheckInIdGenerator(),
  );
}

@riverpod
CheckInTicketUseCase checkInTicketUseCase(Ref ref) {
  return CheckInTicketUseCase(
    ref.watch(checkInRepositoryProvider),
    ref.watch(qrHasherProvider),
  );
}

@riverpod
QueueUnverifiedCheckInUseCase queueUnverifiedCheckInUseCase(Ref ref) {
  return QueueUnverifiedCheckInUseCase(ref.watch(checkInRepositoryProvider));
}

@riverpod
ManualCheckInUseCase manualCheckInUseCase(Ref ref) {
  return ManualCheckInUseCase(ref.watch(checkInRepositoryProvider));
}

@riverpod
GetGuestListUseCase getGuestListUseCase(Ref ref) {
  return GetGuestListUseCase(ref.watch(checkInRepositoryProvider));
}

@riverpod
DownloadGuestListUseCase downloadGuestListUseCase(Ref ref) {
  return DownloadGuestListUseCase(ref.watch(checkInRepositoryProvider));
}

@riverpod
SyncPendingCheckInsUseCase syncPendingCheckInsUseCase(Ref ref) {
  return SyncPendingCheckInsUseCase(ref.watch(checkInRepositoryProvider));
}

/// Read by Home to push offline scans left over from events whose door
/// check-in has closed.
@riverpod
SyncAllPendingCheckInsUseCase syncAllPendingCheckInsUseCase(Ref ref) {
  return SyncAllPendingCheckInsUseCase(ref.watch(checkInRepositoryProvider));
}

@riverpod
GetCheckInSyncStatusUseCase getCheckInSyncStatusUseCase(Ref ref) {
  return GetCheckInSyncStatusUseCase(ref.watch(checkInRepositoryProvider));
}

@riverpod
DismissCheckInConflictUseCase dismissCheckInConflictUseCase(Ref ref) {
  return DismissCheckInConflictUseCase(ref.watch(checkInRepositoryProvider));
}
