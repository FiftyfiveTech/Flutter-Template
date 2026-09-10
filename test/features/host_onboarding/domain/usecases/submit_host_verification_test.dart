import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_payout_details.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_type.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_verification_result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_verification_submission_draft.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_verification_repository.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/usecases/submit_host_verification.dart';

class _FakeHostVerificationRepository implements HostVerificationRepository {
  _FakeHostVerificationRepository(this._result);
  final Result<HostVerificationResult> _result;
  HostVerificationSubmissionDraft? lastDraft;

  @override
  Future<Result<HostVerificationResult>> submit(
    HostVerificationSubmissionDraft draft,
  ) async {
    lastDraft = draft;
    return _result;
  }
}

void main() {
  const draft = HostVerificationSubmissionDraft(
    hostType: HostType.club,
    servesFood: false,
    servesAlcohol: false,
    payoutDetails: HostPayoutDetails(
      method: HostPayoutMethod.upi,
      vpa: 'business@upi',
    ),
    documents: [],
  );

  test(
    'passes the draft through to the repository and returns its result',
    () async {
      const result = HostVerificationResult(accountStatus: 'pending_review');
      final repository = _FakeHostVerificationRepository(const Ok(result));
      final useCase = SubmitHostVerificationUseCase(repository);

      final actual = await useCase(draft);

      expect(repository.lastDraft, draft);
      actual.when(
        ok: (value) => expect(value.accountStatus, 'pending_review'),
        err: (_) => fail('expected Ok'),
      );
    },
  );

  test('surfaces a repository failure unchanged', () async {
    const failure = NetworkFailure(message: 'Submission failed.');
    final repository = _FakeHostVerificationRepository(const Err(failure));
    final useCase = SubmitHostVerificationUseCase(repository);

    final actual = await useCase(draft);

    actual.when(
      ok: (_) => fail('expected Err'),
      err: (value) => expect(value.message, 'Submission failed.'),
    );
  });
}
