/// What the host has earned. Amounts are integer paise (1/100 rupee) so
/// money is never held as a float.
///
/// [totalNetPayoutPaise] and [expectedNetPayoutPaise] are exact figures the
/// server only fills in once settled/confirmed — they are 0 until then.
/// [expectedGrossPaise] is the pre-settlement estimate and can still change
/// with cancellations and refunds.
class HostEarnings {
  const HostEarnings({
    this.totalRevenuePaise = 0,
    this.totalNetPayoutPaise = 0,
    this.expectedGrossPaise = 0,
    this.expectedNetPayoutPaise = 0,
    this.settledEventsCount = 0,
    this.unsettledBookingsCount = 0,
  });

  final int totalRevenuePaise;
  final int totalNetPayoutPaise;
  final int expectedGrossPaise;
  final int expectedNetPayoutPaise;
  final int settledEventsCount;
  final int unsettledBookingsCount;

  /// True once the server has confirmed the exact expected payout.
  bool get isExpectedConfirmed => expectedNetPayoutPaise > 0;
}
