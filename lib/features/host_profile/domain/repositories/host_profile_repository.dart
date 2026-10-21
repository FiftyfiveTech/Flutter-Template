import '../../../../core/error/result.dart';
import '../entities/host_profile.dart';
import '../entities/host_profile_edit.dart';

abstract interface class HostProfileRepository {
  /// The cached profile for [userId], or `null` if none is cached (or the
  /// cache belongs to a different host).
  Future<Result<HostProfile?>> getCached(String userId);

  /// Persists [profile]'s summary fields, keeping any existing avatar and
  /// names.
  Future<Result<void>> cache(HostProfile profile);

  /// Sends [edit] to the server (uploading the photo first, if any) and,
  /// only once that succeeds, writes the result to the local cache.
  /// Returns the updated cached profile.
  Future<Result<HostProfile>> update(String userId, HostProfileEdit edit);

  /// Deletes the host account on the server and, only once that succeeds,
  /// wipes the cached profile and avatar.
  Future<Result<void>> deleteAccount();

  /// Wipes the cached profile and its avatar file (on log out).
  Future<Result<void>> clear();
}
