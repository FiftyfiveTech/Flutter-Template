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

/// Reads are offline-first from Drift (there's no profile GET endpoint).
/// [update] is Strategy A (direct remote): the cache and avatar are only
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
