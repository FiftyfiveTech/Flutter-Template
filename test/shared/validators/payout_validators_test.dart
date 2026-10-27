import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/shared/validators/payout_validators.dart';

void main() {
  group('UPI', () {
    test('accepts valid VPAs and ignores case and padding', () {
      for (final upi in [
        'business@upi',
        'rahul.kumar-1@okhdfcbank',
        ' Name_01@YBL ',
        '9876543210@paytm',
      ]) {
        expect(PayoutValidators.validateUpi(upi), isNull, reason: upi);
      }
      expect(PayoutValidators.normalizeUpi(' Name@YBL '), 'name@ybl');
    });

    test('rejects malformed VPAs', () {
      for (final upi in ['', 'a@upi', 'name', 'name@', '@upi', 'na me@upi']) {
        expect(PayoutValidators.validateUpi(upi), isNotNull, reason: upi);
      }
      expect(PayoutValidators.validateUpi('name@bank1'), isNotNull);
      expect(PayoutValidators.validateUpi(r'na$me@upi'), isNotNull);
    });
  });

  group('IFSC', () {
    test('accepts 4 letters, a zero, then 6 alphanumerics', () {
      expect(PayoutValidators.validateIfsc('HDFC0001234'), isNull);
      expect(PayoutValidators.validateIfsc('sbin0ab12cd'), isNull);
    });

    test('rejects wrong length or a non-zero fifth character', () {
      for (final ifsc in ['', 'HDFC000123', 'HDFC1001234', 'HD1C0001234']) {
        expect(PayoutValidators.validateIfsc(ifsc), isNotNull, reason: ifsc);
      }
    });
  });

  group('account number', () {
    test('accepts 9 to 18 digits', () {
      expect(PayoutValidators.validateAccountNumber('123456789'), isNull);
      expect(
        PayoutValidators.validateAccountNumber('123456789012345678'),
        isNull,
      );
    });

    test('rejects short, long, non-numeric and all-zero values', () {
      for (final number in [
        '',
        '12345678',
        '1234567890123456789',
        '12345678a',
        '000000000',
      ]) {
        expect(
          PayoutValidators.validateAccountNumber(number),
          isNotNull,
          reason: number,
        );
      }
    });

    test('confirmation must match', () {
      expect(
        PayoutValidators.validateConfirmAccountNumber('123456789', '123456789'),
        isNull,
      );
      expect(
        PayoutValidators.validateConfirmAccountNumber('123456780', '123456789'),
        isNotNull,
      );
    });
  });

  group('holder name', () {
    test('accepts letters, spaces, dots, apostrophes and hyphens', () {
      expect(
        PayoutValidators.validateHolderName("Rahul K. O'Neil-Rao"),
        isNull,
      );
    });

    test('rejects empty, digits and one-letter names', () {
      for (final name in ['', '   ', 'R', 'Rahul 2']) {
        expect(PayoutValidators.validateHolderName(name), isNotNull);
      }
    });
  });
}
