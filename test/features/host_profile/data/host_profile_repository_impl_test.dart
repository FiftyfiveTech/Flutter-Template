import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/database/app_database.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/network/base_api_client.dart';
import 'package:host_mobile_app/features/host_profile/data/datasources/host_profile_local_datasource.dart';
import 'package:host_mobile_app/features/host_profile/data/datasources/host_profile_photo_store.dart';
import 'package:host_mobile_app/features/host_profile/data/datasources/host_profile_remote_datasource.dart';
import 'package:host_mobile_app/features/host_profile/data/models/host_profile_dto.dart';
import 'package:host_mobile_app/features/host_profile/data/repository_impl/host_profile_repository_impl.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile_edit.dart';
import 'package:host_mobile_app/features/host_profile/domain/usecases/update_host_profile.dart';

class _FakePhotoStore implements HostProfilePhotoStore {
  final deleted = <String?>[];
  var _counter = 0;

  @override
  Future<String> store(String sourcePath) async => 'stored_${_counter++}.jpg';

  @override
  Future<void> delete(String? path) async => deleted.add(path);
}

class _FakeRemote implements HostProfileRemoteDatasource {
  Object? uploadError;
  Object? updateError;
  Object? deleteError;
  var deleteCalls = 0;
  final uploadedPaths = <String>[];
  UpdateHostProfileRequestDto? lastRequest;

  @override
  Future<HostProfileUploadDto> uploadPhoto(String filePath) async {
    if (uploadError != null) throw uploadError!;
    uploadedPaths.add(filePath);
    return const HostProfileUploadDto(id: 'upload-1');
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<HostProfileResponseDto> updateProfile(
    UpdateHostProfileRequestDto request,
  ) async {
    lastRequest = request;
    if (updateError != null) throw updateError!;
    return HostProfileResponseDto(
      id: 'u1',
      firstName: request.firstName ?? 'Aarav',
      lastName: request.lastName ?? 'Shetty',
      businessName: request.businessName ?? 'Cellar Door',
    );
  }
}

Failure _failure<T>(Result<T> result) =>
    result.when(ok: (v) => fail('expected failure, got $v'), err: (f) => f);

T _value<T>(Result<T> result) =>
    result.when(ok: (v) => v, err: (f) => fail('unexpected $f'));

void main() {
  late AppDatabase db;
  late _FakePhotoStore photoStore;
  late _FakeRemote remote;
  late HostProfileRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    photoStore = _FakePhotoStore();
    remote = _FakeRemote();
    repository = HostProfileRepositoryImpl(
      DriftHostProfileLocalDatasource(db),
      photoStore,
      remote,
    );
  });

  tearDown(() => db.close());

  test('returns the cached profile for the same host', () async {
    await repository.cache(
      const HostProfile(
        userId: 'u1',
        hostName: 'Cellar Door',
        isVerified: true,
      ),
    );

    final cached = _value(await repository.getCached('u1'));

    expect(cached?.hostName, 'Cellar Door');
    expect(cached?.isVerified, isTrue);
  });

  test('hides a different host\'s cached profile', () async {
    await repository.cache(const HostProfile(userId: 'u1', hostName: 'A'));

    expect(_value(await repository.getCached('u2')), isNull);
  });

  test('re-caching the summary keeps the stored avatar and names', () async {
    await repository.update(
      'u1',
      const HostProfileEdit(firstName: 'Aarav', photoSourcePath: '/p/a.jpg'),
    );
    await repository.cache(const HostProfile(userId: 'u1', hostName: 'New'));

    final cached = _value(await repository.getCached('u1'));

    expect(cached?.hostName, 'New');
    expect(cached?.firstName, 'Aarav');
    expect(cached?.photoPath, 'stored_0.jpg');
  });

  test('update sends only the edited fields and caches the response', () async {
    await repository.cache(const HostProfile(userId: 'u1', hostName: 'Old'));

    final updated = _value(
      await repository.update(
        'u1',
        const HostProfileEdit(businessName: 'Cellar Door'),
      ),
    );

    expect(remote.lastRequest?.toJson(), {'businessName': 'Cellar Door'});
    expect(remote.uploadedPaths, isEmpty);
    expect(updated.hostName, 'Cellar Door');
    expect(_value(await repository.getCached('u1'))?.lastName, 'Shetty');
  });

  test('update uploads the stored photo and sends its upload id', () async {
    await repository.update(
      'u1',
      const HostProfileEdit(photoSourcePath: '/p/a.jpg'),
    );
    final updated = _value(
      await repository.update(
        'u1',
        const HostProfileEdit(photoSourcePath: '/p/b.jpg'),
      ),
    );

    expect(remote.uploadedPaths, ['stored_0.jpg', 'stored_1.jpg']);
    expect(remote.lastRequest?.toJson(), {'photoUploadId': 'upload-1'});
    expect(updated.photoPath, 'stored_1.jpg');
    expect(photoStore.deleted, contains('stored_0.jpg'));
  });

  test('a server field error maps to a validation failure and leaves the '
      'cache untouched', () async {
    await repository.cache(const HostProfile(userId: 'u1', hostName: 'Old'));
    remote.updateError = NetworkException(
      'firstName must be shorter than or equal to 50 characters',
      statusCode: 400,
      code: 'VALIDATION_FAILED',
      fieldErrors: const {
        'firstName': 'firstName must be shorter than or equal to 50 characters',
      },
    );

    final failure = _failure(
      await repository.update(
        'u1',
        const HostProfileEdit(firstName: 'x', photoSourcePath: '/p/a.jpg'),
      ),
    );

    expect(failure, isA<HostProfileValidationFailure>());
    expect((failure as HostProfileValidationFailure).fieldErrors.keys, [
      'firstName',
    ]);
    final cached = _value(await repository.getCached('u1'));
    expect(cached?.firstName, isNull);
    expect(cached?.photoPath, isNull);
    expect(photoStore.deleted, contains('stored_0.jpg'));
  });

  test('no response maps to a network failure', () async {
    remote.uploadError = NetworkException('Connection timed out');

    final failure = _failure(
      await repository.update(
        'u1',
        const HostProfileEdit(photoSourcePath: '/p/a.jpg'),
      ),
    );

    expect(failure, isA<NetworkFailure>());
    expect(remote.lastRequest, isNull);
  });

  test(
    'a server rejection without field errors maps to a server failure',
    () async {
      remote.updateError = NetworkException('Forbidden', statusCode: 403);

      final failure = _failure(
        await repository.update('u1', const HostProfileEdit(lastName: 'S')),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Forbidden');
    },
  );

  test('clear wipes the row and the avatar file', () async {
    await repository.update(
      'u1',
      const HostProfileEdit(photoSourcePath: '/p/a.jpg'),
    );
    await repository.clear();

    expect(_value(await repository.getCached('u1')), isNull);
    expect(photoStore.deleted, contains('stored_0.jpg'));
  });

  test('deleteAccount deletes on the server, then wipes the cache', () async {
    await repository.update(
      'u1',
      const HostProfileEdit(photoSourcePath: '/p/a.jpg'),
    );

    _value(await repository.deleteAccount());

    expect(remote.deleteCalls, 1);
    expect(_value(await repository.getCached('u1')), isNull);
    expect(photoStore.deleted, contains('stored_0.jpg'));
  });

  test('a failed deleteAccount keeps the cached profile', () async {
    await repository.cache(const HostProfile(userId: 'u1', hostName: 'A'));
    remote.deleteError = NetworkException(
      'Settle events with sold seats first',
      statusCode: 409,
    );

    final failure = _failure(await repository.deleteAccount());

    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Settle events with sold seats first');
    expect(_value(await repository.getCached('u1'))?.hostName, 'A');
  });
}
