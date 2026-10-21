import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/utils/host_name_fallback.dart';
import '../../../host_home/presentation/controllers/host_home_api_providers.dart';
import '../../../host_onboarding/presentation/controllers/host_is_verified.dart';
import '../../../host_venues/presentation/controllers/host_venues_api_providers.dart';
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
    this.isDeletingAccount = false,
    this.errorMessage,
  });

  final String? hostName;
  final bool isVerified;
  final int savedVenuesCount;
  final String? photoPath;
  final bool isLoading;

  /// True while `DELETE /api/v1/host/me` is in flight.
  final bool isDeletingAccount;
  final String? errorMessage;

  HostYouState copyWith({
    String? hostName,
    bool? isVerified,
    int? savedVenuesCount,
    String? photoPath,
    bool? isLoading,
    bool? isDeletingAccount,
    String? errorMessage,
  }) {
    return HostYouState(
      hostName: hostName ?? this.hostName,
      isVerified: isVerified ?? this.isVerified,
      savedVenuesCount: savedVenuesCount ?? this.savedVenuesCount,
      photoPath: photoPath ?? this.photoPath,
      isLoading: isLoading ?? this.isLoading,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
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
    // The home-summary's savedVenuesCount is placeholder seed data (always
    // 0), so the count comes from the real venues API — same as Home. A
    // failed venues fetch keeps the cached count.
    final summaryFuture = ref.read(getHostHomeSummaryUseCaseProvider)();
    final verifiedFuture = fetchHostIsVerified(ref);
    final venuesFuture = ref.read(getHostVenuesUseCaseProvider)();
    final result = await summaryFuture;
    final fetchedIsVerified = await verifiedFuture;
    final venuesResult = await venuesFuture;
    if (!ref.mounted) return;
    final fetchedVenuesCount = venuesResult.when(
      ok: (venues) => venues.length,
      err: (_) => null,
    );
    state = result.when(
      ok: (summary) {
        final hostName = resolveHostName(summary.hostName, sessionBusinessName);
        final isVerified =
            fetchedIsVerified ?? cached?.isVerified ?? summary.isVerified;
        final savedVenuesCount =
            fetchedVenuesCount ?? cached?.savedVenuesCount ?? 0;
        ref.read(cacheHostProfileUseCaseProvider)(
          HostProfile(
            userId: _userId,
            hostName: hostName,
            isVerified: isVerified,
            savedVenuesCount: savedVenuesCount,
          ),
        );
        return state.copyWith(
          hostName: hostName,
          isVerified: isVerified,
          savedVenuesCount: savedVenuesCount,
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

  /// Deletes the host account. Returns true once the server has deleted
  /// it (the local profile cache is wiped too) — the caller then ends the
  /// session. On failure [HostYouState.errorMessage] is set.
  Future<bool> deleteAccount() async {
    if (state.isDeletingAccount) return false;
    state = state.copyWith(isDeletingAccount: true, errorMessage: null);
    final result = await ref.read(deleteHostAccountUseCaseProvider)();
    if (!ref.mounted) return false;
    return result.when(
      ok: (_) {
        state = state.copyWith(isDeletingAccount: false);
        return true;
      },
      err: (failure) {
        state = state.copyWith(
          isDeletingAccount: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  /// Wipes the cached profile and avatar — call before ending the session.
  Future<void> clearCache() => ref.read(clearHostProfileUseCaseProvider)();
}
