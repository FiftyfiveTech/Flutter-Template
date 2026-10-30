/// A bank a host can pick for payouts. [ifscPrefix] is the four-letter bank
/// code every IFSC of that bank starts with.
class IndianBank {
  const IndianBank(this.name, this.ifscPrefix);

  final String name;
  final String ifscPrefix;
}

/// Hardcoded list of banks offered on the bank details screen.
const indianBanks = <IndianBank>[
  IndianBank('State Bank of India', 'SBIN'),
  IndianBank('HDFC Bank', 'HDFC'),
  IndianBank('ICICI Bank', 'ICIC'),
  IndianBank('Axis Bank', 'UTIB'),
  IndianBank('Kotak Mahindra Bank', 'KKBK'),
  IndianBank('Punjab National Bank', 'PUNB'),
  IndianBank('Bank of Baroda', 'BARB'),
  IndianBank('Canara Bank', 'CNRB'),
  IndianBank('Union Bank of India', 'UBIN'),
  IndianBank('Bank of India', 'BKID'),
  IndianBank('Indian Bank', 'IDIB'),
  IndianBank('Central Bank of India', 'CBIN'),
  IndianBank('IndusInd Bank', 'INDB'),
  IndianBank('Yes Bank', 'YESB'),
  IndianBank('IDFC FIRST Bank', 'IDFB'),
  IndianBank('Federal Bank', 'FDRL'),
  IndianBank('Bandhan Bank', 'BDBL'),
  IndianBank('RBL Bank', 'RATN'),
  IndianBank('South Indian Bank', 'SIBL'),
  IndianBank('Indian Overseas Bank', 'IOBA'),
  IndianBank('UCO Bank', 'UCBA'),
  IndianBank('Bank of Maharashtra', 'MAHB'),
  IndianBank('Punjab & Sind Bank', 'PSIB'),
  IndianBank('Karur Vysya Bank', 'KVBL'),
  IndianBank('AU Small Finance Bank', 'AUBL'),
  IndianBank('Paytm Payments Bank', 'PYTM'),
];

IndianBank? indianBankByName(String? name) {
  for (final bank in indianBanks) {
    if (bank.name == name) return bank;
  }
  return null;
}
