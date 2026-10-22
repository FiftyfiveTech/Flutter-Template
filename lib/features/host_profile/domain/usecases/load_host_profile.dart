import '../../../../core/error/result.dart';
import '../entities/host_profile.dart';
import '../repositories/host_profile_repository.dart';

/// The host's profile, from the cache when this device already has it for
/// [userId]; only on a cache miss (first open after signing in) is it
/// fetched from the server — never on every screen open.
class LoadHostProfileUseCase {
  const LoadHostProfileUseCase(this._repository);

  final HostProfileRepository _repository;

  Future<Result<HostProfile>> call(String userId) async {
    final cached = (await _repository.getCached(
      userId,
    )).when(ok: (p) => p, err: (_) => null);
    if (cached != null) return Ok(cached);
    return _repository.fetch(userId);
  }
}
