import '../../../../core/error/result.dart';
import '../repositories/host_login_repository.dart';

/// Sends an OTP to the given phone number so the host can verify it on the
/// next screen. Only ever called after [ValidatePhoneNumberUseCase] returns
/// `Ok` — this use case does no client-side validation of its own.
class RequestOtpUseCase {
  const RequestOtpUseCase(this._repository);

  final HostLoginRepository _repository;

  Future<Result<void>> call(String phoneNumber) {
    return _repository.requestOtp(phoneNumber);
  }
}
