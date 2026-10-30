/// Formats integer paise as Indian-grouped rupees, e.g. `12450000` →
/// `₹1,24,500`. Fractional paise are shown only when non-zero
/// (`₹1,24,500.50`).
String formatRupees(int paise) {
  final negative = paise < 0;
  final abs = paise.abs();
  final whole = (abs ~/ 100).toString();
  final fraction = abs % 100;

  final grouped = _groupIndian(whole);
  final decimals = fraction == 0
      ? ''
      : '.${fraction.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}₹$grouped$decimals';
}

String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}
