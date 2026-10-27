import '../../../../core/error/result.dart';
import '../entities/host_payout_account.dart';

abstract interface class HostPayoutRepository {
  Future<Result<HostPayoutAccount>> getPayoutAccount();

  Future<Result<HostPayoutAccount>> saveUpi(String upiId);

  Future<Result<HostPayoutAccount>> saveBank(HostBankDetails bank);
}
