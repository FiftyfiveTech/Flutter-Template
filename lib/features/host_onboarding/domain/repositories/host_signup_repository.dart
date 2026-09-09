import '../../../../core/error/result.dart';
import '../entities/host_signup_draft.dart';
import '../entities/host_signup_result.dart';

abstract interface class HostSignupRepository {
  Future<Result<HostSignupResult>> signup(HostSignupDraft draft);
}
