import '../../../../core/error/result.dart';
import '../entities/host_signup_draft.dart';
import '../entities/host_signup_result.dart';
import '../repositories/host_signup_repository.dart';

/// Submits the validated H-01 draft to create the host account. Only ever
/// called after [ValidateHostSignupBasicsUseCase] returns `Ok` — this use
/// case does no client-side validation of its own.
class SignupHostUseCase {
  const SignupHostUseCase(this._repository);

  final HostSignupRepository _repository;

  Future<Result<HostSignupResult>> call(HostSignupDraft draft) {
    return _repository.signup(draft);
  }
}
