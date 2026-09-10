import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/host_onboarding_progress.dart';
import '../../domain/repositories/host_onboarding_progress_repository.dart';
import '../datasources/host_onboarding_progress_local_datasource.dart';

class HostOnboardingProgressRepositoryImpl
    implements HostOnboardingProgressRepository {
  const HostOnboardingProgressRepositoryImpl(this._localDatasource);

  final HostOnboardingProgressLocalDatasource _localDatasource;

  @override
  Future<Result<HostOnboardingProgress?>> load() async {
    try {
      return Ok(await _localDatasource.load());
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<void>> save(HostOnboardingProgress progress) async {
    try {
      await _localDatasource.save(progress);
      return const Ok(null);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _localDatasource.clear();
      return const Ok(null);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }
}
