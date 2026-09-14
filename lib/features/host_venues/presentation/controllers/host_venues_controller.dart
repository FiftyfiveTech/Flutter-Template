import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/host_venue.dart';
import 'host_venues_api_providers.dart';

part 'host_venues_controller.g.dart';

class HostVenuesState {
  const HostVenuesState({
    this.venues = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<HostVenue> venues;
  final bool isLoading;
  final String? errorMessage;

  HostVenuesState copyWith({
    List<HostVenue>? venues,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HostVenuesState(
      venues: venues ?? this.venues,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// H-06 · Venues — loads the host's saved venues list.
@riverpod
class HostVenuesController extends _$HostVenuesController {
  @override
  HostVenuesState build() {
    Future.microtask(loadVenues);
    return const HostVenuesState(isLoading: true);
  }

  Future<void> loadVenues() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final useCase = ref.read(getHostVenuesUseCaseProvider);
    final result = await useCase();
    state = result.when(
      ok: (venues) => state.copyWith(venues: venues, isLoading: false),
      err: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
    );
  }
}
