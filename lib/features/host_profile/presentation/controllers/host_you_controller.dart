import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/utils/host_name_fallback.dart';
import '../../../host_home/presentation/controllers/host_home_api_providers.dart';
import '../../../host_onboarding/presentation/controllers/host_is_verified.dart';
import '../../domain/entities/host_profile.dart';
import 'host_profile_providers.dart';

part 'host_you_controller.g.dart';

class HostYouState {
  const HostYouState({
    this.hostName,
    this.isVerified = false,
    this.savedVenuesCount = 0,
    this.photoPath,
    this.isLoading = false,
    this.isSavingPhoto = false,
    this.errorMessage,
  });

  final String? hostName;
  final bool isVerified;
  final int savedVenuesCount;
  final String? photoPath;
  final bool isLoading;
  final bool isSavingPhoto;
  final String? errorMessage;

  HostYouState copyWith({
    String? hostName,
    bool? isVerified,
    int? savedVenuesCount,
    String? photoPath,
    bool? isLoading,
    bool? isSavingPhoto,
    String? errorMessage,
  }) {
    return HostYouState(
      hostName: hostName ?? this.hostName,
      isVerified: isVerified ?? this.isVerified,
      savedVenuesCount: savedVenuesCount ?? this.savedVenuesCount,
      photoPath: photoPath ?? this.photoPath,
      isLoading: isLoading ?? this.isLoading,
      isSavingPhoto: isSavingPhoto ?? this.isSavingPhoto,
      errorMessage: errorMessage,
    );
  }
}

/// H-12 · You — reuses `host_home`'s summary use case (its domain layer,
/// injected via provider) rather than re-fetching hostName/isVerified
/// through a second datasource; the cross-feature boundary rule allows
/// depending on another feature's domain layer this way.
///
/// Offline-first: the cached profile (incl. the avatar) from Drift is
/// shown immediately, then refreshed from the network when reachable and
/// written back to the cache. A failed refresh keeps the cached values.
@riverpod
class HostYouController extends _$HostYouController {
  @override
  HostYouState build() {
    Future.microtask(load);
    return const HostYouState(isLoading: true);
  }

  String get _userId => ref.read(hostSessionControllerProvider)?.userId ?? '';

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final sessionBusinessName =
        ref.read(hostSessionControllerProvider)?.businessName ?? '';

    final cachedResult = await ref.read(getCachedHostProfileUseCaseProvider)(
      _userId,
    );
    final cached = cachedResult.when(ok: (p) => p, err: (_) => null);
    if (!ref.mounted) return;
    if (cached != null) {
      state = state.copyWith(
        hostName: resolveHostName(cached.hostName, sessionBusinessName),
        isVerified: cached.isVerified,
        savedVenuesCount: cached.savedVenuesCount,
        photoPath: cached.photoPath,
      );
    }

    // Verification comes from the real document-review status (same rule
    // as H-04), not the home-summary placeholder's hardcoded `false`. If
    // that fetch fails, keep the cached value instead of downgrading.
    final summaryFuture = ref.read(getHostHomeSummaryUseCaseProvider)();
    final verifiedFuture = fetchHostIsVerified(ref);
    final result = await summaryFuture;
    final fetchedIsVerified = await verifiedFuture;
    if (!ref.mounted) return;
    state = result.when(
      ok: (summary) {
        final hostName = resolveHostName(summary.hostName, sessionBusinessName);
        final isVerified =
            fetchedIsVerified ?? cached?.isVerified ?? summary.isVerified;
        ref.read(cacheHostProfileUseCaseProvider)(
          HostProfile(
            userId: _userId,
            hostName: hostName,
            isVerified: isVerified,
            savedVenuesCount: summary.savedVenuesCount,
          ),
        );
        return state.copyWith(
          hostName: hostName,
          isVerified: isVerified,
          savedVenuesCount: summary.savedVenuesCount,
          isLoading: false,
        );
      },
      err: (failure) => state.copyWith(
        // With a cached profile on screen, offline isn't an error worth
        // surfacing — the page already shows the last-known values.
        hostName: state.hostName ?? sessionBusinessName,
        isLoading: false,
        errorMessage: cached == null ? failure.message : null,
      ),
    );
  }

  /// Stores [sourcePath] (a just-picked image) as the host's avatar.
  Future<void> setPhoto(String sourcePath) async {
    state = state.copyWith(isSavingPhoto: true, errorMessage: null);
    final result = await ref.read(setHostProfilePhotoUseCaseProvider)(
      _userId,
      sourcePath,
    );
    if (!ref.mounted) return;
    state = result.when(
      ok: (path) => state.copyWith(photoPath: path, isSavingPhoto: false),
      err: (failure) =>
          state.copyWith(isSavingPhoto: false, errorMessage: failure.message),
    );
  }

  /// Wipes the cached profile and avatar — call before ending the session.
  Future<void> clearCache() => ref.read(clearHostProfileUseCaseProvider)();
}
