import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../host_venues/presentation/controllers/host_venues_api_providers.dart';
import '../../domain/entities/host_home_summary.dart';
import 'host_home_api_providers.dart';

part 'host_home_controller.g.dart';

class HostHomeState {
  const HostHomeState({
    this.summary,
    this.isLoading = false,
    this.errorMessage,
    this.selectedTabIndex = 0,
  });

  final HostHomeSummary? summary;
  final bool isLoading;
  final String? errorMessage;
  final int selectedTabIndex;

  HostHomeState copyWith({
    HostHomeSummary? summary,
    bool? isLoading,
    String? errorMessage,
    int? selectedTabIndex,
  }) {
    return HostHomeState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

@riverpod
class HostHomeController extends _$HostHomeController {
  @override
  HostHomeState build() {
    // Initial fetch
    Future.microtask(loadSummary);
    return const HostHomeState(isLoading: true);
  }

  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final useCase = ref.read(getHostHomeSummaryUseCaseProvider);
    final result = await useCase();
    state = result.when(
      ok: (summary) => state.copyWith(summary: summary, isLoading: false),
      err: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
    );
    // The home-summary endpoint's savedVenuesCount is placeholder seed
    // data (no real backend field for it yet) — overwrite it with the
    // actual count from the real venues API so this doesn't show a stale
    // number once venues exist.
    if (state.summary != null) {
      final venuesUseCase = ref.read(getHostVenuesUseCaseProvider);
      final venuesResult = await venuesUseCase();
      venuesResult.when(
        ok: (venues) {
          state = state.copyWith(
            summary: state.summary!.copyWith(savedVenuesCount: venues.length),
          );
        },
        // A failed venues fetch shouldn't break the rest of the home
        // screen — leave the placeholder count in place rather than
        // showing an error for a secondary card.
        err: (_) {},
      );
    }
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}
