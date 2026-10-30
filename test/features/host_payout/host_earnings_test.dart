import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_payout/data/models/host_earnings_dto.dart';
import 'package:host_mobile_app/shared/utils/rupee_format.dart';

void main() {
  test('maps the revenue stats response', () {
    final earnings = HostEarningsDto.fromJson({
      'totalRevenuePaise': 500000,
      'totalNetPayoutPaise': 400000,
      'expectedGrossRevenuePaise': 250000,
      'expectedNetRevenuePaise': 0,
      'settledEventsCount': 5,
      'unsettledBookingsCount': 12,
      'currency': 'INR',
    }).toEntity();
    expect(earnings.totalNetPayoutPaise, 400000);
    expect(earnings.expectedGrossPaise, 250000);
    expect(earnings.settledEventsCount, 5);
    expect(earnings.isExpectedConfirmed, isFalse);
  });

  test('expected payout is confirmed once the net amount is non-zero', () {
    final earnings = HostEarningsDto.fromJson({
      'expectedNetRevenuePaise': 200000,
    }).toEntity();
    expect(earnings.isExpectedConfirmed, isTrue);
  });

  test('formatRupees groups digits the Indian way', () {
    expect(formatRupees(0), '₹0');
    expect(formatRupees(99900), '₹999');
    expect(formatRupees(12450000), '₹1,24,500');
    expect(formatRupees(12450050), '₹1,24,500.50');
    expect(formatRupees(1000000000), '₹1,00,00,000');
  });
}
