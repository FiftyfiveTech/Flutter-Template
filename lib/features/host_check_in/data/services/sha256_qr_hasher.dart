import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/services/qr_hasher.dart';

/// Lowercase hex SHA-256 of the QR string's UTF-8 bytes, the format of
/// the manifest's `qrCodeHash`.
class Sha256QrHasher implements QrHasher {
  const Sha256QrHasher();

  @override
  String hash(String qrCode) => sha256.convert(utf8.encode(qrCode)).toString();
}
