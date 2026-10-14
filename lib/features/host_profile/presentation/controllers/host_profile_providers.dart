import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/database_providers.dart';
import '../../data/datasources/host_profile_local_datasource.dart';
import '../../data/datasources/host_profile_photo_store.dart';
import '../../data/repository_impl/host_profile_repository_impl.dart';
import '../../domain/repositories/host_profile_repository.dart';
import '../../domain/usecases/cache_host_profile.dart';
import '../../domain/usecases/clear_host_profile.dart';
import '../../domain/usecases/get_cached_host_profile.dart';
import '../../domain/usecases/set_host_profile_photo.dart';

part 'host_profile_providers.g.dart';

@riverpod
HostProfileLocalDatasource hostProfileLocalDatasource(Ref ref) {
  return DriftHostProfileLocalDatasource(ref.watch(appDatabaseProvider));
}

@riverpod
HostProfilePhotoStore hostProfilePhotoStore(Ref ref) {
  return const FileHostProfilePhotoStore();
}

@riverpod
HostProfileRepository hostProfileRepository(Ref ref) {
  return HostProfileRepositoryImpl(
    ref.watch(hostProfileLocalDatasourceProvider),
    ref.watch(hostProfilePhotoStoreProvider),
  );
}

@riverpod
GetCachedHostProfileUseCase getCachedHostProfileUseCase(Ref ref) {
  return GetCachedHostProfileUseCase(ref.watch(hostProfileRepositoryProvider));
}

@riverpod
CacheHostProfileUseCase cacheHostProfileUseCase(Ref ref) {
  return CacheHostProfileUseCase(ref.watch(hostProfileRepositoryProvider));
}

@riverpod
SetHostProfilePhotoUseCase setHostProfilePhotoUseCase(Ref ref) {
  return SetHostProfilePhotoUseCase(ref.watch(hostProfileRepositoryProvider));
}

@riverpod
ClearHostProfileUseCase clearHostProfileUseCase(Ref ref) {
  return ClearHostProfileUseCase(ref.watch(hostProfileRepositoryProvider));
}
