/// Bank account a host is paid out to.
class HostBankDetails {
  const HostBankDetails({
    required this.holderName,
    required this.accountNumber,
    required this.ifsc,
  });

  final String holderName;
  final String accountNumber;
  final String ifsc;

  /// The account number with all but the last four digits hidden — the only
  /// form that is ever shown in the UI.
  String get maskedAccountNumber {
    final visible = accountNumber.length <= 4
        ? accountNumber
        : accountNumber.substring(accountNumber.length - 4);
    return '•••• $visible';
  }
}

/// A host's saved payout details. Either one is enough to be paid out, so
/// both are optional.
class HostPayoutAccount {
  const HostPayoutAccount({this.upiId, this.bank});

  final String? upiId;
  final HostBankDetails? bank;

  bool get isEmpty => upiId == null && bank == null;

  HostPayoutAccount copyWith({String? upiId, HostBankDetails? bank}) {
    return HostPayoutAccount(
      upiId: upiId ?? this.upiId,
      bank: bank ?? this.bank,
    );
  }
}
