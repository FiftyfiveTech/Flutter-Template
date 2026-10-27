import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/host_payout_account.dart';
import '../../domain/repositories/host_payout_repository.dart';
import '../datasources/host_payout_datasource.dart';

class HostPayoutRepositoryImpl implements HostPayoutRepository {
  const HostPayoutRepositoryImpl(this._datasource);

  final HostPayoutDatasource _datasource;

  @override
  Future<Result<HostPayoutAccount>> getPayoutAccount() =>
      _guard(_datasource.getPayoutAccount);

  @override
  Future<Result<HostPayoutAccount>> saveUpi(String upiId) =>
      _guard(() => _datasource.saveUpi(upiId));

  @override
  Future<Result<HostPayoutAccount>> saveBank(HostBankDetails bank) =>
      _guard(() => _datasource.saveBank(bank));

  Future<Result<HostPayoutAccount>> _guard(
    Future<HostPayoutAccount> Function() action,
  ) async {
    try {
      return Ok(await action());
    } on Object {
      return const Err(
        ServerFailure(message: "Couldn't save payout details. Try again."),
      );
    }
  }
}
