import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/host_profile.dart';
import '../../domain/repositories/host_profile_repository.dart';
import '../datasources/host_profile_local_datasource.dart';
import '../datasources/host_profile_photo_store.dart';

/// Strategy B (offline-only) — there's no backend profile/avatar endpoint
/// yet, so the profile lives in Drift and the avatar on local disk.
class HostProfileRepositoryImpl implements HostProfileRepository {
  const HostProfileRepositoryImpl(this._localDatasource, this._photoStore);

  final HostProfileLocalDatasource _localDatasource;
  final HostProfilePhotoStore _photoStore;

  @override
  Future<Result<HostProfile?>> getCached(String userId) async {
    try {
      final cached = await _localDatasource.load();
      return Ok(cached?.userId == userId ? cached : null);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<void>> cache(HostProfile profile) async {
    try {
      final existing = await _localDatasource.load();
      final existingPhoto = existing?.userId == profile.userId
          ? existing?.photoPath
          : null;
      await _localDatasource.save(
        profile.copyWith(photoPath: profile.photoPath ?? existingPhoto),
      );
      return const Ok(null);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<String>> setPhoto(String userId, String sourcePath) async {
    try {
      final existing = await _localDatasource.load();
      final storedPath = await _photoStore.store(sourcePath);
      final base = existing != null && existing.userId == userId
          ? existing
          : HostProfile(userId: userId);
      await _localDatasource.save(base.copyWith(photoPath: storedPath));
      await _photoStore.delete(existing?.photoPath);
      return Ok(storedPath);
    } catch (_) {
      return const Err(CacheFailure(message: "Couldn't save that photo"));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      final existing = await _localDatasource.load();
      await _localDatasource.clear();
      await _photoStore.delete(existing?.photoPath);
      return const Ok(null);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }
}
