import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../data/datasources/host_document_remote_datasource.dart';
import '../../data/repository_impl/host_document_repository_impl.dart';
import '../../domain/repositories/host_document_repository.dart';
import '../../domain/usecases/upload_host_document.dart';

part 'host_document_api_providers.g.dart';

@riverpod
HostDocumentRemoteDatasource hostDocumentRemoteDatasource(Ref ref) {
  return HostDocumentRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
HostDocumentRepository hostDocumentRepository(Ref ref) {
  return HostDocumentRepositoryImpl(
    ref.watch(hostDocumentRemoteDatasourceProvider),
  );
}

@riverpod
UploadHostDocumentUseCase uploadHostDocumentUseCase(Ref ref) {
  return UploadHostDocumentUseCase(ref.watch(hostDocumentRepositoryProvider));
}
