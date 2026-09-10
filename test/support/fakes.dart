import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/session/host_session.dart';
import 'package:host_mobile_app/core/session/host_session_local_datasource.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_onboarding_progress.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_onboarding_progress_repository.dart';

/// In-memory stand-in for `HostSessionLocalDatasource` — keeps widget
/// tests off the real Drift/path_provider stack, which isn't mocked in
/// the test environment.
class FakeHostSessionLocalDatasource implements HostSessionLocalDatasource {
  FakeHostSessionLocalDatasource({HostSession? initial}) : _session = initial;

  HostSession? _session;

  @override
  Future<HostSession?> load() async => _session;

  @override
  Future<void> save(HostSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}

/// In-memory stand-in for `HostOnboardingProgressRepository` — same
/// reasoning as [FakeHostSessionLocalDatasource].
class FakeHostOnboardingProgressRepository
    implements HostOnboardingProgressRepository {
  FakeHostOnboardingProgressRepository({HostOnboardingProgress? initial})
    : _progress = initial;

  HostOnboardingProgress? _progress;

  @override
  Future<Result<HostOnboardingProgress?>> load() async => Ok(_progress);

  @override
  Future<Result<void>> save(HostOnboardingProgress progress) async {
    _progress = progress;
    return const Ok(null);
  }

  @override
  Future<Result<void>> clear() async {
    _progress = null;
    return const Ok(null);
  }
}
