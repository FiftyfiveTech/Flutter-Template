import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_document_status_remote_datasource.dart';
import '../../data/repository_impl/host_document_status_repository_impl.dart';
import '../../domain/repositories/host_document_status_repository.dart';
import '../../domain/usecases/get_host_documents_status.dart';

part 'host_document_status_api_providers.g.dart';

@riverpod
HostDocumentStatusRemoteDatasource hostDocumentStatusRemoteDatasource(Ref ref) {
  return HostDocumentStatusRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostDocumentStatusRepository hostDocumentStatusRepository(Ref ref) {
  return HostDocumentStatusRepositoryImpl(
    ref.watch(hostDocumentStatusRemoteDatasourceProvider),
  );
}

@riverpod
GetHostDocumentsStatusUseCase getHostDocumentsStatusUseCase(Ref ref) {
  return GetHostDocumentsStatusUseCase(
    ref.watch(hostDocumentStatusRepositoryProvider),
  );
}
