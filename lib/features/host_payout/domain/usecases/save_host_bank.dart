import '../../../../core/error/result.dart';
import '../../../../shared/validators/payout_validators.dart';
import '../entities/host_payout_account.dart';
import '../repositories/host_payout_repository.dart';
import 'save_host_upi.dart';

class SaveHostBankUseCase {
  const SaveHostBankUseCase(this._repository);

  final HostPayoutRepository _repository;

  Future<Result<HostPayoutAccount>> call({
    required String holderName,
    required String accountNumber,
    required String confirmAccountNumber,
    required String ifsc,
  }) {
    final errors = <String, String>{
      'holderName': ?PayoutValidators.validateHolderName(holderName),
      'accountNumber': ?PayoutValidators.validateAccountNumber(accountNumber),
      'ifsc': ?PayoutValidators.validateIfsc(ifsc),
    };
    if (!errors.containsKey('accountNumber')) {
      final mismatch = PayoutValidators.validateConfirmAccountNumber(
        confirmAccountNumber,
        accountNumber,
      );
      if (mismatch != null) errors['confirmAccountNumber'] = mismatch;
    }
    if (errors.isNotEmpty) {
      return Future.value(Err(HostPayoutValidationFailure(errors)));
    }
    return _repository.saveBank(
      HostBankDetails(
        holderName: PayoutValidators.normalizeHolderName(holderName),
        accountNumber: PayoutValidators.normalizeAccountNumber(accountNumber),
        ifsc: PayoutValidators.normalizeIfsc(ifsc),
      ),
    );
  }
}
