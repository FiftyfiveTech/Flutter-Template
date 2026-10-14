import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/database/app_database.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_profile/data/datasources/host_profile_local_datasource.dart';
import 'package:host_mobile_app/features/host_profile/data/datasources/host_profile_photo_store.dart';
import 'package:host_mobile_app/features/host_profile/data/repository_impl/host_profile_repository_impl.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile.dart';

class _FakePhotoStore implements HostProfilePhotoStore {
  final deleted = <String?>[];
  var _counter = 0;

  @override
  Future<String> store(String sourcePath) async => 'stored_${_counter++}.jpg';

  @override
  Future<void> delete(String? path) async => deleted.add(path);
}

T _value<T>(Result<T> result) =>
    result.when(ok: (v) => v, err: (f) => fail('unexpected $f'));

void main() {
  late AppDatabase db;
  late _FakePhotoStore photoStore;
  late HostProfileRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    photoStore = _FakePhotoStore();
    repository = HostProfileRepositoryImpl(
      DriftHostProfileLocalDatasource(db),
      photoStore,
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

  test('re-caching the summary keeps the stored avatar', () async {
    await repository.setPhoto('u1', '/picked/a.jpg');
    await repository.cache(const HostProfile(userId: 'u1', hostName: 'New'));

    final cached = _value(await repository.getCached('u1'));

    expect(cached?.hostName, 'New');
    expect(cached?.photoPath, 'stored_0.jpg');
  });

  test('replacing the avatar deletes the previous file', () async {
    await repository.setPhoto('u1', '/picked/a.jpg');
    final path = _value(await repository.setPhoto('u1', '/picked/b.jpg'));

    expect(path, 'stored_1.jpg');
    expect(photoStore.deleted, contains('stored_0.jpg'));
  });

  test('clear wipes the row and the avatar file', () async {
    await repository.setPhoto('u1', '/picked/a.jpg');
    await repository.clear();

    expect(_value(await repository.getCached('u1')), isNull);
    expect(photoStore.deleted, contains('stored_0.jpg'));
  });
}
