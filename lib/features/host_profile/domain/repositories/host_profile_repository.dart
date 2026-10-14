import '../../../../core/error/result.dart';
import '../entities/host_profile.dart';

abstract interface class HostProfileRepository {
  /// The cached profile for [userId], or `null` if none is cached (or the
  /// cache belongs to a different host).
  Future<Result<HostProfile?>> getCached(String userId);

  /// Persists [profile]'s summary fields, keeping any existing avatar.
  Future<Result<void>> cache(HostProfile profile);

  /// Copies the picked image at [sourcePath] into private app storage,
  /// replaces any previous avatar, and returns the stored copy's path.
  Future<Result<String>> setPhoto(String userId, String sourcePath);

  /// Wipes the cached profile and its avatar file (on log out).
  Future<Result<void>> clear();
}
