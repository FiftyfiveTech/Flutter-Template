/// Indian payout-detail validators — the single source of truth for UPI,
/// bank account and IFSC rules, shared by the onboarding documents step and
/// the Payout details screens. Each `validate*` returns an error message, or
/// null when the value is valid; each `normalize*` returns the canonical form
/// to submit and store.
abstract final class PayoutValidators {
  // NPCI VPA: `handle@psp` — handle of letters, digits, `.`, `-`, `_`; PSP of letters only.
  static final _upiPattern = RegExp(r'^[a-z0-9._\-]{2,256}@[a-z]{2,64}$');
  static final _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final _accountNumberPattern = RegExp(r'^\d{9,18}$');
  static final _holderNamePattern = RegExp(r"^[A-Za-z][A-Za-z .'\-]{1,99}$");

  static String normalizeUpi(String value) => value.trim().toLowerCase();

  static String normalizeIfsc(String value) => value.trim().toUpperCase();

  static String normalizeAccountNumber(String value) =>
      value.replaceAll(RegExp(r'\s'), '');

  static String normalizeHolderName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String? validateUpi(String value) {
    final upi = normalizeUpi(value);
    if (upi.isEmpty) return 'Enter your UPI ID';
    if (!_upiPattern.hasMatch(upi)) {
      return 'Enter a valid UPI ID, e.g. name@okhdfcbank';
    }
    return null;
  }

  static String? validateHolderName(String value) {
    final name = normalizeHolderName(value);
    if (name.isEmpty) return 'Enter the account holder name';
    if (!_holderNamePattern.hasMatch(name)) {
      return 'Use letters only, as printed on your bank account';
    }
    return null;
  }

  static String? validateAccountNumber(String value) {
    final number = normalizeAccountNumber(value);
    if (number.isEmpty) return 'Enter your account number';
    if (!_accountNumberPattern.hasMatch(number) ||
        RegExp(r'^0+$').hasMatch(number)) {
      return 'Account number must be 9 to 18 digits';
    }
    return null;
  }

  static String? validateConfirmAccountNumber(String value, String original) {
    if (normalizeAccountNumber(value).isEmpty) {
      return 'Re-enter your account number';
    }
    if (normalizeAccountNumber(value) != normalizeAccountNumber(original)) {
      return 'Account numbers do not match';
    }
    return null;
  }

  static String? validateIfsc(String value) {
    final ifsc = normalizeIfsc(value);
    if (ifsc.isEmpty) return 'Enter the IFSC code';
    if (!_ifscPattern.hasMatch(ifsc)) {
      return 'IFSC is 11 characters, e.g. HDFC0001234';
    }
    return null;
  }
}
