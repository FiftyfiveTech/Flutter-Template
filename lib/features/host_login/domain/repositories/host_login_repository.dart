import '../../../../core/error/result.dart';
import '../entities/host_login_result.dart';

abstract interface class HostLoginRepository {
  Future<Result<void>> requestOtp(String phoneNumber);

  Future<Result<HostLoginResult>> verifyOtp(String phoneNumber, String code);
}
