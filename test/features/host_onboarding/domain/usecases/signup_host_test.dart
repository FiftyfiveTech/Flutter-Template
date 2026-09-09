import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_signup_draft.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_signup_result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_signup_repository.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/usecases/signup_host.dart';

class _FakeHostSignupRepository implements HostSignupRepository {
  _FakeHostSignupRepository(this._result);
  final Result<HostSignupResult> _result;
  HostSignupDraft? lastDraft;

  @override
  Future<Result<HostSignupResult>> signup(HostSignupDraft draft) async {
    lastDraft = draft;
    return _result;
  }
}

void main() {
  const draft = HostSignupDraft(
    businessName: 'Cellar Door Collective',
    contactPhone: '+919876543210',
    contactEmail: 'you@business.com',
    city: 'Chennai city',
    cityId: 'city-1',
  );

  test(
    'passes the draft through to the repository and returns its result',
    () async {
      const result = HostSignupResult(
        accessToken: 'token',
        userId: 'user-1',
        accountStatus: 'active',
      );
      final repository = _FakeHostSignupRepository(const Ok(result));
      final useCase = SignupHostUseCase(repository);

      final actual = await useCase(draft);

      expect(repository.lastDraft, draft);
      expect(actual, isA<Ok<HostSignupResult>>());
      actual.when(
        ok: (value) => expect(value.accessToken, 'token'),
        err: (_) => fail('expected Ok'),
      );
    },
  );

  test('surfaces a repository failure unchanged', () async {
    const failure = NetworkFailure(message: 'Request validation failed.');
    final repository = _FakeHostSignupRepository(const Err(failure));
    final useCase = SignupHostUseCase(repository);

    final actual = await useCase(draft);

    actual.when(
      ok: (_) => fail('expected Err'),
      err: (value) => expect(value.message, 'Request validation failed.'),
    );
  });
}
