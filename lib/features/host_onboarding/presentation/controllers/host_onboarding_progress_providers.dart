import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/database_providers.dart';
import '../../data/datasources/host_onboarding_progress_local_datasource.dart';
import '../../data/repository_impl/host_onboarding_progress_repository_impl.dart';
import '../../domain/repositories/host_onboarding_progress_repository.dart';

part 'host_onboarding_progress_providers.g.dart';

@riverpod
HostOnboardingProgressLocalDatasource hostOnboardingProgressLocalDatasource(
  Ref ref,
) {
  return DriftHostOnboardingProgressLocalDatasource(
    ref.watch(appDatabaseProvider),
  );
}

@riverpod
HostOnboardingProgressRepository hostOnboardingProgressRepository(Ref ref) {
  return HostOnboardingProgressRepositoryImpl(
    ref.watch(hostOnboardingProgressLocalDatasourceProvider),
  );
}
