import '../../../../core/error/result.dart';
import '../entities/host_login_result.dart';
import '../repositories/host_login_repository.dart';

/// Verifies the code sent to [phoneNumber] and, on success, returns the
/// session details to sign the host in. Only ever called after
/// [OtpEntryController.submit] confirms a 6-digit code was entered.
class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final HostLoginRepository _repository;

  Future<Result<HostLoginResult>> call(String phoneNumber, String code) {
    return _repository.verifyOtp(phoneNumber, code);
  }
}
