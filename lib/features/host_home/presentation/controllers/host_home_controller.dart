import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/time/server_clock.dart';
import '../../../../core/utils/host_name_fallback.dart';
import '../../../host_events/domain/entities/host_event.dart';
import '../../../host_events/presentation/controllers/host_events_api_providers.dart';
import '../../../host_onboarding/presentation/controllers/host_is_verified.dart';
import '../../../host_venues/presentation/controllers/host_venues_api_providers.dart';
import '../../domain/entities/host_home_event.dart';
import '../../domain/entities/host_home_summary.dart';
import 'host_home_api_providers.dart';

part 'host_home_controller.g.dart';

class HostHomeState {
  const HostHomeState({
    this.summary,
    this.isLoading = false,
    this.isLoadingDetails = false,
    this.errorMessage,
    this.selectedTabIndex = 0,
  });

  final HostHomeSummary? summary;
  final bool isLoading;

  /// True while the real venues-count/events fetches (which override the
  /// placeholder summary's own empty defaults) are still in flight. The
  /// venues card and events section show shimmer placeholders during this
  /// window instead of a premature "no venues"/"no events yet" — those
  /// empty states only mean something once the real fetches have actually
  /// resolved (or failed).
  final bool isLoadingDetails;
  final String? errorMessage;
  final int selectedTabIndex;

  HostHomeState copyWith({
    HostHomeSummary? summary,
    bool? isLoading,
    bool? isLoadingDetails,
    String? errorMessage,
    int? selectedTabIndex,
  }) {
    return HostHomeState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
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
    // The home-summary placeholder always reports isVerified: false, so
    // verification comes from the real document-review status (the same
    // source as H-04) — fetched alongside so the badge never flashes
    // "Pending" for a verified host.
    final summaryFuture = ref.read(getHostHomeSummaryUseCaseProvider)();
    final verifiedFuture = fetchHostIsVerified(ref);
    final result = await summaryFuture;
    final isVerified = await verifiedFuture;
    if (!ref.mounted) return;
    final sessionBusinessName =
        ref.read(hostSessionControllerProvider)?.businessName ?? '';
    state = result.when(
      ok: (summary) => state.copyWith(
        summary: summary.copyWith(
          hostName: resolveHostName(summary.hostName, sessionBusinessName),
          // A failed status fetch keeps the last-known value on refresh.
          isVerified:
              isVerified ?? state.summary?.isVerified ?? summary.isVerified,
        ),
        isLoading: false,
      ),
      err: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
    );
    if (state.summary == null) return;

    state = state.copyWith(isLoadingDetails: true);

    // The home-summary endpoint's savedVenuesCount is placeholder seed
    // data (no real backend field for it yet) — overwrite it with the
    // actual count from the real venues API so this doesn't show a stale
    // number once venues exist.
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

    // Same reasoning as savedVenuesCount above: the home-summary
    // endpoint's own events are placeholder seed data — overwrite them
    // with the real list from the events API.
    final eventsUseCase = ref.read(getHostEventsUseCaseProvider);
    final eventsResult = await eventsUseCase();
    eventsResult.when(
      ok: (events) {
        final now = ref.read(serverClockProvider).now();
        state = state.copyWith(
          summary: state.summary!.copyWith(
            events: events.map((e) => _toHostHomeEvent(e, now)).toList(),
          ),
        );
      },
      // A failed events fetch shouldn't break the rest of the home
      // screen — leave the placeholder list in place rather than
      // showing an error for the whole page.
      err: (_) {},
    );

    state = state.copyWith(isLoadingDetails: false);
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `"Thu, 12 Sep · 8:00 PM · Venue Name"`, matching the H-05 design's event
/// card copy — built from [HostEvent] since the real API has no
/// pre-formatted schedule string of its own.
String _formatSchedule(HostEvent event) {
  final start = event.startAt;
  if (start == null) return event.venueName;
  final weekday = _weekdayNames[start.weekday - 1];
  final month = _monthNames[start.month - 1];
  final hour12 = start.hour % 12 == 0 ? 12 : start.hour % 12;
  final minute = start.minute.toString().padLeft(2, '0');
  final period = start.hour < 12 ? 'AM' : 'PM';
  final when = '$weekday, ${start.day} $month · $hour12:$minute $period';
  return event.venueName.isEmpty ? when : '$when · ${event.venueName}';
}

/// Maps the backend's publish lifecycle to the status Home's card shows.
/// `published` is split by time against [now] (server-corrected, see
/// [ServerClock]) since the backend has no live/ended status of its own:
/// before start → upcoming, start..end → live, after end → completed.
/// With no end time, a started event counts as completed — there's no way
/// to tell how long it runs.
@visibleForTesting
HostEventStatus toHostHomeStatus(HostEvent event, DateTime now) {
  switch (event.status) {
    case HostEventLifecycleStatus.draft:
    case HostEventLifecycleStatus.unknown:
      return HostEventStatus.draft;
    case HostEventLifecycleStatus.submitted:
      return HostEventStatus.inReview;
    case HostEventLifecycleStatus.cancelled:
      return HostEventStatus.cancelled;
    case HostEventLifecycleStatus.completed:
      return HostEventStatus.completed;
    case HostEventLifecycleStatus.published:
      final start = event.startAt;
      final end = event.endAt;
      if (start == null || now.isBefore(start)) return HostEventStatus.upcoming;
      if (end != null && now.isBefore(end)) return HostEventStatus.live;
      return HostEventStatus.completed;
  }
}

HostHomeEvent _toHostHomeEvent(HostEvent event, DateTime now) {
  return HostHomeEvent(
    id: event.id,
    title: event.title,
    formattedSchedule: _formatSchedule(event),
    status: toHostHomeStatus(event, now),
    // The real events API has no sold-count field yet.
    soldCount: null,
    capacity: event.capacity,
  );
}
