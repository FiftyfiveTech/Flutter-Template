import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/base_api_client.dart';
import '../../domain/entities/host_profile.dart';
import '../../domain/entities/host_profile_edit.dart';
import '../../domain/repositories/host_profile_repository.dart';
import '../../domain/usecases/update_host_profile.dart';
import '../datasources/host_profile_local_datasource.dart';
import '../datasources/host_profile_photo_store.dart';
import '../datasources/host_profile_remote_datasource.dart';
import '../models/host_profile_dto.dart';

/// Reads are offline-first: [getCached] serves the Drift copy instantly and
/// [fetch] refreshes it from `GET /api/v1/host`. [update] is Strategy A (direct remote): the cache and avatar are only
/// replaced after `PATCH /api/v1/host/profile` succeeds.
class HostProfileRepositoryImpl implements HostProfileRepository {
  const HostProfileRepositoryImpl(
    this._localDatasource,
    this._photoStore,
    this._remoteDatasource,
  );

  final HostProfileLocalDatasource _localDatasource;
  final HostProfilePhotoStore _photoStore;
  final HostProfileRemoteDatasource _remoteDatasource;

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
  Future<Result<HostProfile>> fetch(String userId) async {
    final HostProfileResponseDto remote;
    try {
      remote = await _remoteDatasource.getProfile();
    } on NetworkException catch (e) {
      return Err(_failureFor(e));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }

    final existing = await _loadCacheQuietly();
    final base = existing != null && existing.userId == userId
        ? existing
        : HostProfile(userId: userId);
    final fetched = base.copyWith(
      hostName: remote.businessName,
      firstName: remote.firstName,
      lastName: remote.lastName,
      isVerified: remote.isVerified,
      avgRating: remote.avgRating,
      photoPath: base.photoPath == null
          ? await _downloadAvatar(remote.photoUrl)
          : null,
    );
    // A failed cache write mustn't hide a successful fetch — the screen
    // still gets the fresh values, they just won't survive a restart.
    try {
      await _localDatasource.save(fetched);
    } catch (_) {}
    return Ok(fetched);
  }

  /// Stores a local copy of the server's avatar, or `null` if there is
  /// none or it can't be downloaded — the avatar then falls back to
  /// initials rather than failing the whole fetch.
  Future<String?> _downloadAvatar(String? url) async {
    if (url == null || url.isEmpty) return null;
    String? temp;
    try {
      temp = await _remoteDatasource.downloadPhoto(url);
      return await _photoStore.store(temp);
    } catch (_) {
      return null;
    } finally {
      if (temp != null) await _discard(temp);
    }
  }

  Future<HostProfile?> _loadCacheQuietly() async {
    try {
      return await _localDatasource.load();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<void>> cache(HostProfile profile) async {
    try {
      final existing = await _localDatasource.load();
      final sameHost = existing?.userId == profile.userId;
      await _localDatasource.save(
        HostProfile(
          userId: profile.userId,
          hostName: profile.hostName,
          firstName:
              profile.firstName ?? (sameHost ? existing?.firstName : null),
          lastName: profile.lastName ?? (sameHost ? existing?.lastName : null),
          isVerified: profile.isVerified,
          savedVenuesCount: profile.savedVenuesCount,
          photoPath:
              profile.photoPath ?? (sameHost ? existing?.photoPath : null),
        ),
      );
      return const Ok(null);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<HostProfile>> update(
    String userId,
    HostProfileEdit edit,
  ) async {
    // The compressed private copy is both what gets uploaded and what the
    // avatar shows afterwards; it's discarded if the server rejects it.
    String? storedPhoto;
    try {
      String? photoUploadId;
      if (edit.photoSourcePath != null) {
        storedPhoto = await _photoStore.store(edit.photoSourcePath!);
        photoUploadId = (await _remoteDatasource.uploadPhoto(storedPhoto)).id;
      }

      final saved = await _remoteDatasource.updateProfile(
        UpdateHostProfileRequestDto.fromEdit(
          edit,
          photoUploadId: photoUploadId,
        ),
      );

      final existing = await _localDatasource.load();
      final base = existing != null && existing.userId == userId
          ? existing
          : HostProfile(userId: userId);
      final updated = base.copyWith(
        hostName: saved.businessName,
        firstName: saved.firstName,
        lastName: saved.lastName,
        photoPath: storedPhoto,
      );
      await _localDatasource.save(updated);
      if (storedPhoto != null) await _photoStore.delete(base.photoPath);
      return Ok(updated);
    } on NetworkException catch (e) {
      await _discard(storedPhoto);
      return Err(_failureFor(e));
    } catch (_) {
      await _discard(storedPhoto);
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _remoteDatasource.deleteAccount();
    } on NetworkException catch (e) {
      return Err(_failureFor(e));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
    // The account is gone server-side; a failed local wipe mustn't
    // report the delete as failed (and invite a retry against a deleted
    // account) — sign-out clears the session either way.
    await clear();
    return const Ok(null);
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

  Failure _failureFor(NetworkException e) {
    if (e.fieldErrors.isNotEmpty) {
      return HostProfileValidationFailure(e.fieldErrors, message: e.message);
    }
    // No response at all (timeout / no connection) vs. a server rejection.
    if (e.statusCode == null) return NetworkFailure(message: e.message);
    return ServerFailure(message: e.message);
  }

  Future<void> _discard(String? path) async {
    try {
      await _photoStore.delete(path);
    } catch (_) {}
  }
}
