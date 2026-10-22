import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/session_providers.dart';
import '../../../../core/time/server_clock.dart';
import '../../../../core/utils/host_name_fallback.dart';
import '../../../host_check_in/presentation/controllers/check_in_api_providers.dart';
import '../../../host_events/domain/entities/host_event.dart';
import '../../../host_events/presentation/controllers/host_events_api_providers.dart';
import '../../../host_onboarding/presentation/controllers/host_is_verified.dart';
import '../../../host_profile/presentation/controllers/host_profile_providers.dart';
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
    // The header name comes from the session's business name, which Edit
    // profile updates while Home stays mounted underneath — mirror it
    // live rather than only on the next loadSummary.
    ref.listen(hostSessionControllerProvider, (previous, next) {
      final businessName = next?.businessName ?? '';
      final summary = state.summary;
      if (businessName == (previous?.businessName ?? '') ||
          businessName.isEmpty ||
          summary == null) {
        return;
      }
      state = state.copyWith(summary: summary.copyWith(hostName: businessName));
    });
    // Initial fetch
    Future.microtask(loadSummary);
    return const HostHomeState(isLoading: true);
  }

  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // Door check-in closes when an event ends, so offline scans still
    // queued on this phone are pushed from here. Fire-and-forget: the
    // queue survives a failed attempt and is retried on the next load.
    unawaited(ref.read(syncAllPendingCheckInsUseCaseProvider)());
    // The home-summary placeholder always reports isVerified: false, so
    // verification comes from the real document-review status (the same
    // source as H-04) — fetched alongside so the badge never flashes
    // "Pending" for a verified host.
    //
    // The host name comes from the cached profile. Right after sign-in the
    // cache is empty (sign-out wipes it, OTP login returns no profile), so
    // this is where `GET /api/v1/host` runs — once; later opens and the
    // Profile tab read the cache.
    final session = ref.read(hostSessionControllerProvider);
    final summaryFuture = ref.read(getHostHomeSummaryUseCaseProvider)();
    final verifiedFuture = fetchHostIsVerified(ref);
    final profileFuture = ref.read(loadHostProfileUseCaseProvider)(
      session?.userId ?? '',
    );
    final result = await summaryFuture;
    final isVerified = await verifiedFuture;
    final profileName = (await profileFuture).when(
      ok: (profile) => profile.hostName,
      err: (_) => '',
    );
    if (!ref.mounted) return;
    final sessionBusinessName =
        ref.read(hostSessionControllerProvider)?.businessName ?? '';
    state = result.when(
      ok: (summary) => state.copyWith(
        summary: summary.copyWith(
          hostName: resolveHostName(
            profileName.isNotEmpty ? profileName : summary.hostName,
            sessionBusinessName,
          ),
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
            events: sortForHome(
              events.map((e) => _toHostHomeEvent(e, now)).toList(),
            ),
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
      if (event.hasEndedAt(now)) return HostEventStatus.completed;
      final start = event.startAt;
      if (start == null || now.isBefore(start)) return HostEventStatus.upcoming;
      return HostEventStatus.live;
  }
}

/// Completed events sink below everything else (live, upcoming, drafts…)
/// so what still needs the host's attention stays at the top. Otherwise
/// the API's order is kept — this is a stable partition, not a re-sort.
@visibleForTesting
List<HostHomeEvent> sortForHome(List<HostHomeEvent> events) {
  bool isCompleted(HostHomeEvent e) => e.status == HostEventStatus.completed;
  return [
    ...events.where((e) => !isCompleted(e)),
    ...events.where(isCompleted),
  ];
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
    canCheckIn: canOpenCheckIn(event, now),
  );
}

/// Door check-in opens [checkInOpensBefore] the start (so the offline
/// guest list can be downloaded while venue wifi still works) and closes
/// when the event ends — nothing can be done to an ended event. Offline
/// scans still queued at that point are synced from Home instead (see
/// [HostHomeController.loadSummary]).
@visibleForTesting
const checkInOpensBefore = Duration(hours: 12);

@visibleForTesting
bool canOpenCheckIn(HostEvent event, DateTime now) {
  if (event.status != HostEventLifecycleStatus.published) return false;
  if (event.hasEndedAt(now)) return false;
  final start = event.startAt;
  if (start == null) return false;
  return !now.isBefore(start.subtract(checkInOpensBefore));
}
