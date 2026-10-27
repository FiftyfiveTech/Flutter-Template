import '../../domain/entities/host_payout_account.dart';

abstract interface class HostPayoutDatasource {
  Future<HostPayoutAccount> getPayoutAccount();

  Future<HostPayoutAccount> saveUpi(String upiId);

  Future<HostPayoutAccount> saveBank(HostBankDetails bank);
}

/// Stand-in until the payout endpoint is decided: holds the details in
/// memory for the app session. Swap the provider in
/// `host_payout_providers.dart` for a REST implementation (wrapping
/// `BaseApiClient`) — nothing above the data layer changes.
class InMemoryHostPayoutDatasource implements HostPayoutDatasource {
  HostPayoutAccount _account = const HostPayoutAccount();

  @override
  Future<HostPayoutAccount> getPayoutAccount() async => _account;

  @override
  Future<HostPayoutAccount> saveUpi(String upiId) async {
    _account = _account.copyWith(upiId: upiId);
    return _account;
  }

  @override
  Future<HostPayoutAccount> saveBank(HostBankDetails bank) async {
    _account = _account.copyWith(bank: bank);
    return _account;
  }
}
