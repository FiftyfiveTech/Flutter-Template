import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/utils/host_name_fallback.dart';
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

/// H-12 · You — profile summary, venues count and verification badge.
///
/// The profile (incl. the avatar) is read from the Drift cache — opening
/// this tab never calls the profile API. `GET /api/v1/host` only runs on a
/// cache miss (normally already done by Home right after sign-in) and
/// after an Edit profile save. Venues count and verification are still
/// refreshed live; a failed refresh keeps the cached values.
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

    final verifiedFuture = fetchHostIsVerified(ref);
    final venuesFuture = ref.read(getHostVenuesUseCaseProvider)();

    final profileResult = await ref.read(loadHostProfileUseCaseProvider)(
      _userId,
    );
    if (!ref.mounted) return;
    final profile = profileResult.when(ok: (p) => p, err: (_) => null);
    state = state.copyWith(
      hostName: resolveHostName(profile?.hostName ?? '', sessionBusinessName),
      isVerified: profile?.isVerified,
      savedVenuesCount: profile?.savedVenuesCount,
      photoPath: profile?.photoPath,
      // No cached profile and the fetch failed — nothing real to show.
      errorMessage: profileResult.when(
        ok: (_) => null,
        err: (failure) => failure.message,
      ),
    );

    // Verification comes from the real document-review status (same rule
    // as H-04); the count from the real venues API — same as Home. A
    // failed fetch keeps the profile's value instead of downgrading.
    final fetchedIsVerified = await verifiedFuture;
    final venuesResult = await venuesFuture;
    if (!ref.mounted) return;
    final fetchedVenuesCount = venuesResult.when(
      ok: (venues) => venues.length,
      err: (_) => null,
    );
    final isVerified = fetchedIsVerified ?? state.isVerified;
    final savedVenuesCount = fetchedVenuesCount ?? state.savedVenuesCount;
    if (profile != null) {
      ref.read(cacheHostProfileUseCaseProvider)(
        HostProfile(
          userId: _userId,
          hostName: profile.hostName,
          isVerified: isVerified,
          savedVenuesCount: savedVenuesCount,
        ),
      );
    }
    state = state.copyWith(
      isVerified: isVerified,
      savedVenuesCount: savedVenuesCount,
      isLoading: false,
      errorMessage: state.errorMessage,
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
