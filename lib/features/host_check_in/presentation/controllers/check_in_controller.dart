import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/time/server_clock.dart';
import '../../domain/entities/check_in_attendee.dart';
import '../../domain/entities/check_in_conflict.dart';
import '../../domain/entities/check_in_outcome.dart';
import '../../domain/entities/check_in_result.dart';
import 'check_in_api_providers.dart';

part 'check_in_controller.g.dart';

enum CheckInConnection { unknown, online, offline }

const _unset = Object();

class CheckInState {
  const CheckInState({
    this.attendees = const [],
    this.isLoading = false,
    this.loadErrorMessage,
    this.connection = CheckInConnection.unknown,
    this.manifestDownloadedAt,
    this.isManifestExpired = false,
    this.pendingCount = 0,
    this.conflicts = const [],
    this.isSyncing = false,
    this.isProcessingScan = false,
    this.scanResult,
  });

  final List<CheckInAttendee> attendees;
  final bool isLoading;
  final String? loadErrorMessage;
  final CheckInConnection connection;

  /// When the offline guest list on this device was downloaded; `null`
  /// if there isn't one.
  final DateTime? manifestDownloadedAt;
  final bool isManifestExpired;

  /// Check-ins made offline on this device and not yet synced.
  final int pendingCount;
  final List<CheckInConflict> conflicts;
  final bool isSyncing;
  final bool isProcessingScan;

  /// The result card currently shown on the scanner.
  final CheckInResult? scanResult;

  bool get hasManifest => manifestDownloadedAt != null;
  int get checkedInCount => attendees.where((a) => a.checkedIn).length;
  int get totalCount => attendees.length;

  CheckInState copyWith({
    List<CheckInAttendee>? attendees,
    bool? isLoading,
    Object? loadErrorMessage = _unset,
    CheckInConnection? connection,
    Object? manifestDownloadedAt = _unset,
    bool? isManifestExpired,
    int? pendingCount,
    List<CheckInConflict>? conflicts,
    bool? isSyncing,
    bool? isProcessingScan,
    Object? scanResult = _unset,
  }) {
    return CheckInState(
      attendees: attendees ?? this.attendees,
      isLoading: isLoading ?? this.isLoading,
      loadErrorMessage: loadErrorMessage == _unset
          ? this.loadErrorMessage
          : loadErrorMessage as String?,
      connection: connection ?? this.connection,
      manifestDownloadedAt: manifestDownloadedAt == _unset
          ? this.manifestDownloadedAt
          : manifestDownloadedAt as DateTime?,
      isManifestExpired: isManifestExpired ?? this.isManifestExpired,
      pendingCount: pendingCount ?? this.pendingCount,
      conflicts: conflicts ?? this.conflicts,
      isSyncing: isSyncing ?? this.isSyncing,
      isProcessingScan: isProcessingScan ?? this.isProcessingScan,
      scanResult: scanResult == _unset
          ? this.scanResult
          : scanResult as CheckInResult?,
    );
  }
}

/// HOST-OPS-02/03 · Door check-in for one event, shared by the hub, the
/// scanner and the guest list (all three are on the stack together).
///
/// While open it re-syncs every [_tickInterval]: pushes queued offline
/// check-ins, refreshes the guest list (so other door devices' scans
/// show up in the count) and re-downloads the offline guest list before
/// it expires.
@riverpod
class CheckInController extends _$CheckInController {
  static const _tickInterval = Duration(seconds: 30);
  static const _manifestRefreshMargin = Duration(minutes: 5);

  /// The same code is ignored until it has been out of the camera's view
  /// for this long, so a guest still holding up their phone after the
  /// result card closes isn't re-scanned as "already checked in".
  static const _sameCodeQuietPeriod = Duration(seconds: 3);

  String? _lastCode;
  DateTime? _lastCodeSeenAt;
  bool _refreshing = false;
  DateTime? _manifestExpiresAt;

  @override
  CheckInState build(String eventId) {
    final timer = Timer.periodic(_tickInterval, (_) => refresh(quiet: true));
    ref.onDispose(timer.cancel);
    Future.microtask(refresh);
    return const CheckInState(isLoading: true);
  }

  DateTime _now() => ref.read(serverClockProvider).now();

  /// Syncs queued check-ins, then reloads the guest list and the offline
  /// manifest. [quiet] skips the full-screen loading state.
  Future<void> refresh({bool quiet = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      if (!quiet) {
        state = state.copyWith(
          isLoading: state.attendees.isEmpty,
          loadErrorMessage: null,
        );
      }
      await _sync();
      if (!ref.mounted) return;
      await Future.wait([_loadGuestList(), _refreshManifestIfNeeded()]);
      if (!ref.mounted) return;
      await _loadSyncStatus();
    } finally {
      _refreshing = false;
    }
  }

  /// Host-triggered sync from the hub. Returns a one-line summary to show.
  Future<String> syncNow() async {
    final message = await _sync();
    if (!ref.mounted) return message;
    await _loadGuestList();
    if (!ref.mounted) return message;
    await _loadSyncStatus();
    return message;
  }

  Future<String> _sync() async {
    if (state.isSyncing) return 'A sync is already running.';
    state = state.copyWith(isSyncing: true);
    final result = await ref.read(syncPendingCheckInsUseCaseProvider)(eventId);
    if (!ref.mounted) return '';
    state = state.copyWith(isSyncing: false);
    return result.when(
      ok: (report) {
        if (report.acceptedCount > 0 || report.conflicts.isNotEmpty) {
          state = state.copyWith(connection: CheckInConnection.online);
        }
        return _syncSummary(
          report.acceptedCount,
          report.conflicts.length,
          report.remainingCount,
        );
      },
      err: (failure) {
        if (failure is NetworkFailure) {
          state = state.copyWith(connection: CheckInConnection.offline);
          return "Still offline. Check-ins stay saved on this phone and "
              'will sync once you reconnect.';
        }
        return failure.message;
      },
    );
  }

  String _syncSummary(int accepted, int rejected, int remaining) {
    if (accepted == 0 && rejected == 0 && remaining == 0) {
      return 'Everything is synced.';
    }
    final parts = [
      if (accepted > 0) '$accepted synced',
      if (rejected > 0) '$rejected rejected (see below)',
      if (remaining > 0) '$remaining still waiting',
    ];
    return '${parts.join(', ')}.';
  }

  Future<void> _loadGuestList() async {
    final result = await ref.read(getGuestListUseCaseProvider)(eventId);
    if (!ref.mounted) return;
    state = result.when(
      ok: (list) => state.copyWith(
        attendees: list.attendees,
        isLoading: false,
        loadErrorMessage: null,
        connection: list.isOffline
            ? CheckInConnection.offline
            : CheckInConnection.online,
      ),
      err: (failure) => state.copyWith(
        isLoading: false,
        loadErrorMessage: failure.message,
        connection: failure is NetworkFailure
            ? CheckInConnection.offline
            : state.connection,
      ),
    );
  }

  Future<void> _refreshManifestIfNeeded() async {
    final expiresAt = _manifestExpiresAt;
    final fresh =
        expiresAt != null &&
        _now().add(_manifestRefreshMargin).isBefore(expiresAt);
    if (fresh && state.hasManifest) return;
    await ref.read(downloadGuestListUseCaseProvider)(eventId);
  }

  Future<void> _loadSyncStatus() async {
    final result = await ref.read(getCheckInSyncStatusUseCaseProvider)(eventId);
    if (!ref.mounted) return;
    if (result case Ok(:final value)) {
      final manifest = value.manifest;
      _manifestExpiresAt = manifest?.expiresAt;
      state = state.copyWith(
        pendingCount: value.pending.length,
        conflicts: value.conflicts,
        manifestDownloadedAt: manifest?.downloadedAt,
        isManifestExpired: manifest?.isExpiredAt(_now()) ?? false,
      );
    }
  }

  /// Called for every code the camera detects.
  Future<void> scan(String rawCode) async {
    final now = _now();
    final isSameCode = rawCode == _lastCode;
    final lastSeen = _lastCodeSeenAt;
    _lastCode = rawCode;
    _lastCodeSeenAt = now;
    if (isSameCode &&
        lastSeen != null &&
        now.difference(lastSeen) < _sameCodeQuietPeriod) {
      return;
    }
    if (state.isProcessingScan || state.scanResult != null) return;

    state = state.copyWith(isProcessingScan: true);
    final result = await ref.read(checkInTicketUseCaseProvider)(
      eventId: eventId,
      qrCode: rawCode,
      now: now,
    );
    if (!ref.mounted) return;
    _showResult(result, CheckInMethod.qr);
  }

  /// Lets an offline scan that couldn't be verified in, queued for the
  /// server to verify on sync.
  Future<void> queueCurrentScanForVerification() async {
    final qrCode = state.scanResult?.qrCode;
    if (qrCode == null || state.isProcessingScan) return;
    state = state.copyWith(isProcessingScan: true);
    final result = await ref.read(queueUnverifiedCheckInUseCaseProvider)(
      eventId: eventId,
      qrCode: qrCode,
      now: _now(),
    );
    if (!ref.mounted) return;
    _showResult(result, CheckInMethod.qr);
  }

  void dismissResult() {
    state = state.copyWith(scanResult: null);
  }

  Future<CheckInResult> manualCheckIn(CheckInAttendee attendee) async {
    final result = await ref.read(manualCheckInUseCaseProvider)(
      eventId: eventId,
      attendee: attendee,
      now: _now(),
    );
    if (!ref.mounted) return _resultOrError(result, CheckInMethod.manual);
    final shown = _resultOrError(result, CheckInMethod.manual);
    _afterDecision(shown);
    return shown;
  }

  Future<void> dismissConflict(String scanId) async {
    await ref.read(dismissCheckInConflictUseCaseProvider)(scanId);
    if (!ref.mounted) return;
    state = state.copyWith(
      conflicts: [
        for (final c in state.conflicts)
          if (c.scanId != scanId) c,
      ],
    );
  }

  void _showResult(Result<CheckInResult> result, CheckInMethod method) {
    final shown = _resultOrError(result, method);
    state = state.copyWith(isProcessingScan: false, scanResult: shown);
    _afterDecision(shown);
  }

  /// A failure that isn't a ticket decision (auth expired, local storage
  /// error) still has to be shown at the door as "not let in".
  CheckInResult _resultOrError(
    Result<CheckInResult> result,
    CheckInMethod method,
  ) {
    return result.when(
      ok: (r) => r,
      err: (failure) => CheckInResult(
        outcome: CheckInOutcome.rejected,
        method: method,
        message: failure.message,
      ),
    );
  }

  void _afterDecision(CheckInResult result) {
    final reachedServer =
        !result.isOffline && result.outcome != CheckInOutcome.rejected;
    if (result.isOffline || reachedServer) {
      state = state.copyWith(
        connection: result.isOffline
            ? CheckInConnection.offline
            : CheckInConnection.online,
      );
    }
    if (result.outcome.isAdmitted ||
        result.outcome == CheckInOutcome.alreadyCheckedIn) {
      // Refresh the count and list in the background, without blocking
      // the next scan.
      unawaited(_reloadAfterCheckIn());
    }
  }

  Future<void> _reloadAfterCheckIn() async {
    await _loadGuestList();
    if (!ref.mounted) return;
    await _loadSyncStatus();
  }
}
