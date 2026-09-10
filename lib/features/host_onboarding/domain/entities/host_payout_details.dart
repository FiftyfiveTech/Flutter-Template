/// Payout method a host is verified with. Only UPI is collected by H-03
/// today; `bank` is modeled ahead of the fields existing so the submit-
/// verification request shape doesn't need to change when they're added.
enum HostPayoutMethod { upi, bank }

extension HostPayoutMethodApi on HostPayoutMethod {
  String get apiValue => switch (this) {
    HostPayoutMethod.upi => 'upi',
    HostPayoutMethod.bank => 'bank',
  };
}

/// Payout details submitted with `POST /api/v1/host/submit-verification`.
class HostPayoutDetails {
  const HostPayoutDetails({required this.method, this.vpa});

  final HostPayoutMethod method;

  /// UPI VPA, e.g. `business@upi`. Required when [method] is
  /// [HostPayoutMethod.upi].
  final String? vpa;
}
