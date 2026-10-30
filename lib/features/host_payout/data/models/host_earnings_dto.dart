import '../../domain/entities/host_earnings.dart';

/// `data` of `GET /api/v1/host/payouts/revenue/stats`.
class HostEarningsDto {
  const HostEarningsDto({
    required this.totalRevenuePaise,
    required this.totalNetPayoutPaise,
    required this.expectedGrossRevenuePaise,
    required this.expectedNetRevenuePaise,
    required this.settledEventsCount,
    required this.unsettledBookingsCount,
  });

  factory HostEarningsDto.fromJson(Map<String, dynamic> json) {
    int paise(String key) => (json[key] as num?)?.toInt() ?? 0;
    return HostEarningsDto(
      totalRevenuePaise: paise('totalRevenuePaise'),
      totalNetPayoutPaise: paise('totalNetPayoutPaise'),
      expectedGrossRevenuePaise: paise('expectedGrossRevenuePaise'),
      expectedNetRevenuePaise: paise('expectedNetRevenuePaise'),
      settledEventsCount: paise('settledEventsCount'),
      unsettledBookingsCount: paise('unsettledBookingsCount'),
    );
  }

  final int totalRevenuePaise;
  final int totalNetPayoutPaise;
  final int expectedGrossRevenuePaise;
  final int expectedNetRevenuePaise;
  final int settledEventsCount;
  final int unsettledBookingsCount;

  HostEarnings toEntity() => HostEarnings(
    totalRevenuePaise: totalRevenuePaise,
    totalNetPayoutPaise: totalNetPayoutPaise,
    expectedGrossPaise: expectedGrossRevenuePaise,
    expectedNetPayoutPaise: expectedNetRevenuePaise,
    settledEventsCount: settledEventsCount,
    unsettledBookingsCount: unsettledBookingsCount,
  );
}
