import '../../../../core/error/result.dart';
import '../entities/host_verification_result.dart';
import '../entities/host_verification_submission_draft.dart';

abstract interface class HostVerificationRepository {
  Future<Result<HostVerificationResult>> submit(
    HostVerificationSubmissionDraft draft,
  );
}
