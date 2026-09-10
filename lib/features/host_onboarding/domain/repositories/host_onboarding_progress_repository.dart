import '../../../../core/error/result.dart';
import '../entities/host_onboarding_progress.dart';

abstract interface class HostOnboardingProgressRepository {
  Future<Result<HostOnboardingProgress?>> load();
  Future<Result<void>> save(HostOnboardingProgress progress);
  Future<Result<void>> clear();
}
