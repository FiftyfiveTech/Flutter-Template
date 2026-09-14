import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_venues_remote_datasource.dart';
import '../../data/repository_impl/host_venues_repository_impl.dart';
import '../../domain/repositories/host_venues_repository.dart';
import '../../domain/usecases/delete_host_venue.dart';
import '../../domain/usecases/get_host_venue_by_id.dart';
import '../../domain/usecases/get_host_venues.dart';
import '../../domain/usecases/save_host_venue.dart';
import '../../domain/usecases/upload_venue_photo.dart';

part 'host_venues_api_providers.g.dart';

@riverpod
HostVenuesRemoteDatasource hostVenuesRemoteDatasource(Ref ref) {
  return HostVenuesRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostVenuesRepository hostVenuesRepository(Ref ref) {
  return HostVenuesRepositoryImpl(
    ref.watch(hostVenuesRemoteDatasourceProvider),
  );
}

@riverpod
GetHostVenuesUseCase getHostVenuesUseCase(Ref ref) {
  return GetHostVenuesUseCase(ref.watch(hostVenuesRepositoryProvider));
}

@riverpod
SaveHostVenueUseCase saveHostVenueUseCase(Ref ref) {
  return SaveHostVenueUseCase(ref.watch(hostVenuesRepositoryProvider));
}

@riverpod
DeleteHostVenueUseCase deleteHostVenueUseCase(Ref ref) {
  return DeleteHostVenueUseCase(ref.watch(hostVenuesRepositoryProvider));
}

@riverpod
GetHostVenueByIdUseCase getHostVenueByIdUseCase(Ref ref) {
  return GetHostVenueByIdUseCase(ref.watch(hostVenuesRepositoryProvider));
}

@riverpod
UploadVenuePhotoUseCase uploadVenuePhotoUseCase(Ref ref) {
  return UploadVenuePhotoUseCase(ref.watch(hostVenuesRepositoryProvider));
}
