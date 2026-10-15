import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/database/app_database.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/network/base_api_client.dart';
import 'package:host_mobile_app/features/host_check_in/data/datasources/check_in_local_datasource.dart';
import 'package:host_mobile_app/features/host_check_in/data/models/check_in_manifest_dto.dart';
import 'package:host_mobile_app/features/host_check_in/data/models/check_in_sync_dto.dart';
import 'package:host_mobile_app/features/host_check_in/data/repository_impl/check_in_repository_impl.dart';
import 'package:host_mobile_app/features/host_check_in/data/services/check_in_id_generator.dart';
import 'package:host_mobile_app/features/host_check_in/domain/entities/check_in_outcome.dart';
import 'package:host_mobile_app/features/host_check_in/domain/entities/check_in_result.dart';

import '../support/fake_check_in_remote.dart';

T _value<T>(Result<T> result) =>
    result.when(ok: (v) => v, err: (f) => fail('unexpected $f'));

const _event = 'evt-1';
final _scannedAt = DateTime(2026, 10, 14, 21);

CheckInManifestDto _manifest({List<CheckInManifestAttendeeDto>? attendees}) {
  return CheckInManifestDto(
    manifestVersion: 1,
    serverSignature: 'sig',
    issuedAt: DateTime(2026, 10, 14, 18),
    expiresAt: DateTime(2026, 10, 15, 2),
    attendees:
        attendees ??
        const [
          CheckInManifestAttendeeDto(
            bookingId: 'b1',
            userId: 'u1',
            firstName: 'Asha',
            qrCodeHash: 'h1',
            alreadyCheckedIn: false,
          ),
          CheckInManifestAttendeeDto(
            bookingId: 'b2',
            userId: 'u2',
            firstName: 'Ravi',
            qrCodeHash: 'h2',
            alreadyCheckedIn: false,
          ),
        ],
  );
}

void main() {
  late AppDatabase db;
  late FakeCheckInRemote remote;
  late CheckInRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeCheckInRemote();
    repository = CheckInRepositoryImpl(
      remote,
      DriftCheckInLocalDatasource(db),
      CheckInIdGenerator(),
    );
  });

  tearDown(() => db.close());

  group('scanOnline', () {
    test('maps a valid response to accepted', () async {
      final result = _value(
        await repository.scanOnline(eventId: _event, qrCode: 'qr'),
      );
      expect(result.outcome, CheckInOutcome.accepted);
      expect(result.attendeeName, 'Asha');
      expect(result.isOffline, isFalse);
    });

    test('a 409 ticket rejection is a door decision, not a failure', () async {
      remote.scanError = NetworkException(
        'Ticket already used',
        statusCode: 409,
        code: 'ALREADY_CHECKED_IN',
      );
      final result = _value(
        await repository.scanOnline(eventId: _event, qrCode: 'qr'),
      );
      expect(result.outcome, CheckInOutcome.alreadyCheckedIn);
      expect(result.message, 'Ticket already used');
    });

    test('no response at all is a NetworkFailure (offline fallback)', () async {
      remote.scanError = offline();
      final result = await repository.scanOnline(eventId: _event, qrCode: 'qr');
      expect(result, isA<Err<CheckInResult>>());
      expect((result as Err).failure, isA<NetworkFailure>());
    });

    test('a 5xx also falls back offline', () async {
      remote.scanError = NetworkException('boom', statusCode: 503);
      final result = await repository.scanOnline(eventId: _event, qrCode: 'qr');
      expect((result as Err).failure, isA<NetworkFailure>());
    });

    test('401 is a ServerFailure, never shown as a bad ticket', () async {
      remote.scanError = NetworkException('Expired', statusCode: 401);
      final result = await repository.scanOnline(eventId: _event, qrCode: 'qr');
      expect((result as Err).failure, isA<ServerFailure>());
    });

    test('uses one stable device id across calls', () async {
      await repository.scanOnline(eventId: _event, qrCode: 'a');
      await repository.scanOnline(eventId: _event, qrCode: 'b');
      expect(remote.deviceIds, hasLength(1));
    });
  });

  group('manifest', () {
    test('re-applies still-queued check-ins to a fresh download', () async {
      remote.manifest = _manifest();
      await repository.queueCheckIn(
        eventId: _event,
        method: CheckInMethod.qr,
        scannedAt: _scannedAt,
        qrCode: 'qr1',
        bookingId: 'b1',
      );
      final manifest = _value(await repository.downloadManifest(_event));
      final asha = manifest.attendees.firstWhere((a) => a.bookingId == 'b1');
      final ravi = manifest.attendees.firstWhere((a) => a.bookingId == 'b2');
      expect(asha.alreadyCheckedIn, isTrue);
      expect(ravi.alreadyCheckedIn, isFalse);
    });

    test('queueing marks the cached manifest', () async {
      remote.manifest = _manifest();
      await repository.downloadManifest(_event);
      await repository.queueCheckIn(
        eventId: _event,
        method: CheckInMethod.qr,
        scannedAt: _scannedAt,
        qrCode: 'qr2',
        bookingId: 'b2',
      );
      final cached = _value(await repository.getCachedManifest(_event))!;
      expect(
        cached.attendees
            .firstWhere((a) => a.bookingId == 'b2')
            .alreadyCheckedIn,
        isTrue,
      );
    });
  });

  group('syncPendingCheckIns', () {
    Future<void> queue(String qr, {String? bookingId, String? name}) =>
        repository.queueCheckIn(
          eventId: _event,
          method: CheckInMethod.qr,
          scannedAt: _scannedAt,
          qrCode: qr,
          bookingId: bookingId,
          attendeeName: name,
        );

    test(
      'accepted scans leave the queue; rejected ones become conflicts',
      () async {
        await queue('good', bookingId: 'b1');
        await queue('dupe', bookingId: 'b2', name: 'Ravi');
        final winning = DateTime.utc(2026, 10, 14, 20, 30);
        remote.onSync = (scans) => [
          for (final s in scans)
            CheckInSyncResultDto(
              scanId: s.scanId,
              outcome: s.qrCode == 'good' ? 'accepted' : 'already_checked_in',
              winningDeviceId: 'other-device',
              winningScannedAt: winning,
            ),
        ];

        final report = _value(await repository.syncPendingCheckIns(_event));

        expect(report.acceptedCount, 1);
        expect(report.conflicts, hasLength(1));
        expect(report.conflicts.single.attendeeName, 'Ravi');
        expect(report.remainingCount, 0);
        expect(_value(await repository.getPendingCheckIns(_event)), isEmpty);
        final conflicts = _value(await repository.getConflicts(_event));
        expect(conflicts.single.outcome, CheckInOutcome.alreadyCheckedIn);
        expect(conflicts.single.winningScannedAt, winning.toLocal());
      },
    );

    test("this device's own earlier scan is not a conflict", () async {
      await queue('qr', bookingId: 'b1');
      remote.onSync = (scans) => [
        for (final s in scans)
          CheckInSyncResultDto(
            scanId: s.scanId,
            outcome: 'already_checked_in',
            winningDeviceId: remote.deviceIds.single,
          ),
      ];

      final report = _value(await repository.syncPendingCheckIns(_event));

      expect(report.acceptedCount, 1);
      expect(report.conflicts, isEmpty);
      expect(_value(await repository.getConflicts(_event)), isEmpty);
    });

    test('still offline keeps everything queued and reports failure', () async {
      await queue('qr', bookingId: 'b1');
      remote.syncError = offline();

      final result = await repository.syncPendingCheckIns(_event);

      expect((result as Err).failure, isA<NetworkFailure>());
      expect(_value(await repository.getPendingCheckIns(_event)), hasLength(1));
    });

    test('a scan the server did not report on stays queued', () async {
      await queue('a');
      await queue('b');
      remote.onSync = (scans) => [
        CheckInSyncResultDto(scanId: scans.first.scanId, outcome: 'accepted'),
      ];

      final report = _value(await repository.syncPendingCheckIns(_event));

      expect(report.acceptedCount, 1);
      expect(report.remainingCount, 1);
      expect(_value(await repository.getPendingCheckIns(_event)), hasLength(1));
    });

    test('manual check-ins replay through the manual endpoint', () async {
      await repository.queueCheckIn(
        eventId: _event,
        method: CheckInMethod.manual,
        scannedAt: _scannedAt,
        bookingId: 'b1',
        attendeeName: 'Asha',
      );

      final report = _value(await repository.syncPendingCheckIns(_event));

      expect(remote.manualCalls, ['b1']);
      expect(remote.syncCalls, isEmpty);
      expect(report.acceptedCount, 1);
    });

    test('dismissing a conflict removes it', () async {
      await queue('bad');
      remote.onSync = (scans) => [
        CheckInSyncResultDto(
          scanId: scans.single.scanId,
          outcome: 'invalid_signature',
        ),
      ];
      await repository.syncPendingCheckIns(_event);
      final conflict = _value(await repository.getConflicts(_event)).single;
      expect(conflict.outcome, CheckInOutcome.invalidTicket);

      await repository.dismissConflict(conflict.scanId);

      expect(_value(await repository.getConflicts(_event)), isEmpty);
    });
  });
}
