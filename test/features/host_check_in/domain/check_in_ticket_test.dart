import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/database/app_database.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/network/base_api_client.dart';
import 'package:host_mobile_app/features/host_check_in/data/datasources/check_in_local_datasource.dart';
import 'package:host_mobile_app/features/host_check_in/data/models/check_in_manifest_dto.dart';
import 'package:host_mobile_app/features/host_check_in/data/repository_impl/check_in_repository_impl.dart';
import 'package:host_mobile_app/features/host_check_in/data/services/check_in_id_generator.dart';
import 'package:host_mobile_app/features/host_check_in/data/services/sha256_qr_hasher.dart';
import 'package:host_mobile_app/features/host_check_in/domain/entities/check_in_attendee.dart';
import 'package:host_mobile_app/features/host_check_in/domain/entities/check_in_outcome.dart';
import 'package:host_mobile_app/features/host_check_in/domain/usecases/check_in_ticket.dart';
import 'package:host_mobile_app/features/host_check_in/domain/usecases/get_guest_list.dart';
import 'package:host_mobile_app/features/host_check_in/domain/usecases/manual_check_in.dart';

import '../support/fake_check_in_remote.dart';

T _value<T>(Result<T> result) =>
    result.when(ok: (v) => v, err: (f) => fail('unexpected $f'));

const _event = 'evt-1';
const _hasher = Sha256QrHasher();
final _now = DateTime(2026, 10, 14, 21);

void main() {
  late AppDatabase db;
  late FakeCheckInRemote remote;
  late CheckInRepositoryImpl repository;
  late CheckInTicketUseCase checkIn;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeCheckInRemote();
    repository = CheckInRepositoryImpl(
      remote,
      DriftCheckInLocalDatasource(db),
      CheckInIdGenerator(),
    );
    checkIn = CheckInTicketUseCase(repository, _hasher);
  });

  tearDown(() => db.close());

  Future<void> downloadManifest({
    DateTime? expiresAt,
    bool alreadyCheckedIn = false,
  }) async {
    remote.manifest = CheckInManifestDto(
      manifestVersion: 1,
      serverSignature: 'sig',
      issuedAt: _now.subtract(const Duration(hours: 3)),
      expiresAt: expiresAt ?? _now.add(const Duration(hours: 3)),
      attendees: [
        CheckInManifestAttendeeDto(
          bookingId: 'b1',
          userId: 'u1',
          firstName: 'Asha',
          qrCodeHash: _hasher.hash('ticket-asha').toUpperCase(),
          alreadyCheckedIn: alreadyCheckedIn,
        ),
      ],
    );
    _value(await repository.downloadManifest(_event));
  }

  test('online accept also marks the offline list', () async {
    await downloadManifest();

    final result = _value(
      await checkIn(eventId: _event, qrCode: 'ticket-asha', now: _now),
    );

    expect(result.outcome, CheckInOutcome.accepted);
    final cached = _value(await repository.getCachedManifest(_event))!;
    expect(cached.attendees.single.alreadyCheckedIn, isTrue);
  });

  group('offline', () {
    setUp(() => remote.scanError = offline());

    test('a matching ticket is admitted and queued', () async {
      await downloadManifest();

      final result = _value(
        await checkIn(eventId: _event, qrCode: 'ticket-asha', now: _now),
      );

      expect(result.outcome, CheckInOutcome.accepted);
      expect(result.isOffline, isTrue);
      expect(result.attendeeName, 'Asha');
      final pending = _value(await repository.getPendingCheckIns(_event));
      expect(pending.single.bookingId, 'b1');
      expect(pending.single.qrCode, 'ticket-asha');
    });

    test('the same ticket scanned twice is caught as already used', () async {
      await downloadManifest();
      await checkIn(eventId: _event, qrCode: 'ticket-asha', now: _now);

      final second = _value(
        await checkIn(eventId: _event, qrCode: 'ticket-asha', now: _now),
      );

      expect(second.outcome, CheckInOutcome.alreadyCheckedIn);
      expect(_value(await repository.getPendingCheckIns(_event)), hasLength(1));
    });

    test('a ticket not in the list is not admitted', () async {
      await downloadManifest();

      final result = _value(
        await checkIn(eventId: _event, qrCode: 'forged', now: _now),
      );

      expect(result.outcome, CheckInOutcome.notOnGuestList);
      expect(result.qrCode, 'forged');
      expect(_value(await repository.getPendingCheckIns(_event)), isEmpty);
    });

    test('an expired list is not trusted', () async {
      await downloadManifest(expiresAt: _now);

      final result = _value(
        await checkIn(eventId: _event, qrCode: 'ticket-asha', now: _now),
      );

      expect(result.outcome, CheckInOutcome.guestListExpired);
      expect(_value(await repository.getPendingCheckIns(_event)), isEmpty);
    });

    test('no downloaded list at all', () async {
      final result = _value(
        await checkIn(eventId: _event, qrCode: 'ticket-asha', now: _now),
      );
      expect(result.outcome, CheckInOutcome.noGuestList);
    });
  });

  test('a server rejection is never retried offline', () async {
    await downloadManifest();
    remote.scanError = NetworkException(
      'Wrong event',
      statusCode: 422,
      code: 'WRONG_EVENT',
    );

    final result = _value(
      await checkIn(eventId: _event, qrCode: 'ticket-asha', now: _now),
    );

    expect(result.outcome, CheckInOutcome.wrongEvent);
    expect(_value(await repository.getPendingCheckIns(_event)), isEmpty);
  });

  test('blank scans are invalid without calling the server', () async {
    final result = _value(
      await checkIn(eventId: _event, qrCode: '  ', now: _now),
    );
    expect(result.outcome, CheckInOutcome.invalidTicket);
    expect(remote.deviceIds, isEmpty);
  });

  group('manual check-in offline', () {
    test('is queued and shows as pending on the offline guest list', () async {
      await downloadManifest();
      remote.manualError = offline();
      remote.attendeesError = offline();
      const guest = CheckInAttendee(
        bookingId: 'b1',
        userId: 'u1',
        firstName: 'Asha',
      );

      final result = _value(
        await ManualCheckInUseCase(repository)(
          eventId: _event,
          attendee: guest,
          now: _now,
        ),
      );
      final list = _value(await GetGuestListUseCase(repository)(_event));

      expect(result.outcome, CheckInOutcome.accepted);
      expect(result.isOffline, isTrue);
      expect(list.isOffline, isTrue);
      expect(list.attendees.single.checkedIn, isTrue);
    });
  });
}
