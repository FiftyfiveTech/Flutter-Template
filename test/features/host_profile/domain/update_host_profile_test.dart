import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile_edit.dart';
import 'package:host_mobile_app/features/host_profile/domain/repositories/host_profile_repository.dart';
import 'package:host_mobile_app/features/host_profile/domain/usecases/update_host_profile.dart';

class _FakeRepository implements HostProfileRepository {
  HostProfileEdit? lastEdit;

  @override
  Future<Result<HostProfile>> update(
    String userId,
    HostProfileEdit edit,
  ) async {
    lastEdit = edit;
    return Ok(HostProfile(userId: userId));
  }

  @override
  Future<Result<void>> cache(HostProfile profile) async => const Ok(null);

  @override
  Future<Result<void>> clear() async => const Ok(null);

  @override
  Future<Result<void>> deleteAccount() async => const Ok(null);

  @override
  Future<Result<HostProfile?>> getCached(String userId) async => const Ok(null);
}

void main() {
  late _FakeRepository repository;
  late UpdateHostProfileUseCase useCase;

  setUp(() {
    repository = _FakeRepository();
    useCase = UpdateHostProfileUseCase(repository);
  });

  Map<String, String> errorsOf(Result<HostProfile> result) => result.when(
    ok: (_) => fail('expected a validation failure'),
    err: (f) => (f as HostProfileValidationFailure).fieldErrors,
  );

  test('trims fields before saving', () async {
    await useCase('u1', const HostProfileEdit(firstName: '  Aarav '));

    expect(repository.lastEdit?.firstName, 'Aarav');
  });

  test('leaves unedited (null) fields out', () async {
    await useCase('u1', const HostProfileEdit(lastName: 'Shetty'));

    expect(repository.lastEdit?.firstName, isNull);
    expect(repository.lastEdit?.businessName, isNull);
  });

  test('rejects a blank edited field without calling the repository', () async {
    final errors = errorsOf(
      await useCase(
        'u1',
        const HostProfileEdit(firstName: '  ', businessName: ''),
      ),
    );

    expect(errors.keys, unorderedEquals(['firstName', 'businessName']));
    expect(repository.lastEdit, isNull);
  });

  test('allows names at the max length and rejects one past it', () async {
    final atLimit = 'a' * hostNameMaxLength;
    await useCase('u1', HostProfileEdit(lastName: atLimit));
    expect(repository.lastEdit?.lastName, atLimit);

    final errors = errorsOf(
      await useCase('u1', HostProfileEdit(lastName: '${atLimit}a')),
    );
    expect(errors.keys, ['lastName']);
  });

  test('business name allows up to 200 characters', () async {
    final atLimit = 'b' * hostBusinessNameMaxLength;
    await useCase('u1', HostProfileEdit(businessName: atLimit));
    expect(repository.lastEdit?.businessName, atLimit);

    final errors = errorsOf(
      await useCase('u1', HostProfileEdit(businessName: '${atLimit}b')),
    );
    expect(errors.keys, ['businessName']);
  });
}
