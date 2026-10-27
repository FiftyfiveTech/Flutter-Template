import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../shared/validators/payout_validators.dart';
import '../entities/host_payout_account.dart';
import '../repositories/host_payout_repository.dart';

/// Field-level validation errors keyed by form field name (`upiId`,
/// `holderName`, `accountNumber`, `confirmAccountNumber`, `ifsc`).
class HostPayoutValidationFailure extends ValidationFailure {
  const HostPayoutValidationFailure(this.fieldErrors)
    : super(message: 'Please fix the highlighted fields.');

  final Map<String, String> fieldErrors;
}

class SaveHostUpiUseCase {
  const SaveHostUpiUseCase(this._repository);

  final HostPayoutRepository _repository;

  Future<Result<HostPayoutAccount>> call(String upiId) {
    final error = PayoutValidators.validateUpi(upiId);
    if (error != null) {
      return Future.value(Err(HostPayoutValidationFailure({'upiId': error})));
    }
    return _repository.saveUpi(PayoutValidators.normalizeUpi(upiId));
  }
}
