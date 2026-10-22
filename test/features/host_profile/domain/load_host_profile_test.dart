import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile_edit.dart';
import 'package:host_mobile_app/features/host_profile/domain/repositories/host_profile_repository.dart';
import 'package:host_mobile_app/features/host_profile/domain/usecases/load_host_profile.dart';

class _FakeRepository implements HostProfileRepository {
  _FakeRepository({this.cached, this.fetchResult});

  final HostProfile? cached;
  final Result<HostProfile>? fetchResult;
  var fetchCalls = 0;

  @override
  Future<Result<HostProfile?>> getCached(String userId) async => Ok(cached);

  @override
  Future<Result<HostProfile>> fetch(String userId) async {
    fetchCalls++;
    return fetchResult!;
  }

  @override
  Future<Result<void>> cache(HostProfile profile) => throw UnimplementedError();

  @override
  Future<Result<HostProfile>> update(String userId, HostProfileEdit edit) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteAccount() => throw UnimplementedError();

  @override
  Future<Result<void>> clear() => throw UnimplementedError();
}

void main() {
  test('serves a cached profile without calling the API', () async {
    final repository = _FakeRepository(
      cached: const HostProfile(userId: 'u1', hostName: 'Cached'),
    );

    final result = await LoadHostProfileUseCase(repository)('u1');

    expect(repository.fetchCalls, 0);
    result.when(
      ok: (p) => expect(p.hostName, 'Cached'),
      err: (f) => fail('unexpected $f'),
    );
  });

  test('fetches once on a cache miss (first open after sign-in)', () async {
    final repository = _FakeRepository(
      fetchResult: const Ok(HostProfile(userId: 'u1', hostName: 'Fetched')),
    );

    final result = await LoadHostProfileUseCase(repository)('u1');

    expect(repository.fetchCalls, 1);
    result.when(
      ok: (p) => expect(p.hostName, 'Fetched'),
      err: (f) => fail('unexpected $f'),
    );
  });

  test('surfaces the fetch failure when nothing is cached', () async {
    final repository = _FakeRepository(
      fetchResult: const Err(NetworkFailure(message: 'Offline')),
    );

    final result = await LoadHostProfileUseCase(repository)('u1');

    result.when(
      ok: (_) => fail('expected failure'),
      err: (f) => expect(f, isA<NetworkFailure>()),
    );
  });
}
