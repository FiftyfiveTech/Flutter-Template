import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/host_earnings.dart';
import '../../domain/entities/host_payout_account.dart';
import '../../domain/repositories/host_payout_repository.dart';
import '../datasources/host_earnings_datasource.dart';
import '../datasources/host_payout_datasource.dart';

class HostPayoutRepositoryImpl implements HostPayoutRepository {
  const HostPayoutRepositoryImpl(this._datasource, this._earnings);

  final HostPayoutDatasource _datasource;
  final HostEarningsDatasource _earnings;

  @override
  Future<Result<HostEarnings>> getEarnings() async {
    try {
      return Ok((await _earnings.getRevenueStats()).toEntity());
    } on Object {
      return const Err(
        ServerFailure(message: "Couldn't load your earnings. Try again."),
      );
    }
  }

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
