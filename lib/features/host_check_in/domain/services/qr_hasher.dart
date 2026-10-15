/// Hashes a scanned QR the same way the server hashed it into the
/// manifest's `qrCodeHash`, so a ticket can be matched offline without
/// the manifest ever holding the codes themselves.
abstract interface class QrHasher {
  String hash(String qrCode);
}
