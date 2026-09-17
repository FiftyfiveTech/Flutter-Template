import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_events_remote_datasource.dart';
import '../../data/repository_impl/host_events_repository_impl.dart';
import '../../domain/repositories/host_events_repository.dart';
import '../../domain/usecases/get_host_event_by_id.dart';
import '../../domain/usecases/get_host_events.dart';
import '../../domain/usecases/save_host_event.dart';
import '../../domain/usecases/upload_event_photo.dart';

part 'host_events_api_providers.g.dart';

@riverpod
HostEventsRemoteDatasource hostEventsRemoteDatasource(Ref ref) {
  return HostEventsRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostEventsRepository hostEventsRepository(Ref ref) {
  return HostEventsRepositoryImpl(
    ref.watch(hostEventsRemoteDatasourceProvider),
  );
}

@riverpod
GetHostEventsUseCase getHostEventsUseCase(Ref ref) {
  return GetHostEventsUseCase(ref.watch(hostEventsRepositoryProvider));
}

@riverpod
GetHostEventByIdUseCase getHostEventByIdUseCase(Ref ref) {
  return GetHostEventByIdUseCase(ref.watch(hostEventsRepositoryProvider));
}

@riverpod
SaveHostEventUseCase saveHostEventUseCase(Ref ref) {
  return SaveHostEventUseCase(ref.watch(hostEventsRepositoryProvider));
}

@riverpod
UploadEventPhotoUseCase uploadEventPhotoUseCase(Ref ref) {
  return UploadEventPhotoUseCase(ref.watch(hostEventsRepositoryProvider));
}
