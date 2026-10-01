import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/utils/host_name_fallback.dart';
import '../../../host_home/presentation/controllers/host_home_api_providers.dart';

part 'host_you_controller.g.dart';

class HostYouState {
  const HostYouState({
    this.hostName,
    this.isVerified = false,
    this.savedVenuesCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final String? hostName;
  final bool isVerified;
  final int savedVenuesCount;
  final bool isLoading;
  final String? errorMessage;

  HostYouState copyWith({
    String? hostName,
    bool? isVerified,
    int? savedVenuesCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HostYouState(
      hostName: hostName ?? this.hostName,
      isVerified: isVerified ?? this.isVerified,
      savedVenuesCount: savedVenuesCount ?? this.savedVenuesCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// H-12 · You — reuses `host_home`'s summary use case (its domain layer,
/// injected via provider) rather than re-fetching hostName/isVerified
/// through a second datasource; the cross-feature boundary rule allows
/// depending on another feature's domain layer this way.
@riverpod
class HostYouController extends _$HostYouController {
  @override
  HostYouState build() {
    Future.microtask(load);
    return const HostYouState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final useCase = ref.read(getHostHomeSummaryUseCaseProvider);
    final result = await useCase();
    final sessionBusinessName =
        ref.read(hostSessionControllerProvider)?.businessName ?? '';
    state = result.when(
      ok: (summary) => state.copyWith(
        hostName: resolveHostName(summary.hostName, sessionBusinessName),
        isVerified: summary.isVerified,
        savedVenuesCount: summary.savedVenuesCount,
        isLoading: false,
      ),
      err: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
    );
  }
}
