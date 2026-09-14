import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}
