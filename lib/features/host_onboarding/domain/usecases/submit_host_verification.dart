import '../../../../core/error/result.dart';
import '../entities/host_verification_result.dart';
import '../entities/host_verification_submission_draft.dart';
import '../repositories/host_verification_repository.dart';

/// Submits the completed H-02/H-03 draft for review. Only ever called
/// once every required document has an `uploadId` — this use case does
/// no client-side completeness validation of its own.
class SubmitHostVerificationUseCase {
  const SubmitHostVerificationUseCase(this._repository);

  final HostVerificationRepository _repository;

  Future<Result<HostVerificationResult>> call(
    HostVerificationSubmissionDraft draft,
  ) {
    return _repository.submit(draft);
  }
}
