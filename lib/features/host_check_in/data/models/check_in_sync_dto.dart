/// One offline scan in a `POST .../checkin/sync` request.
class CheckInSyncScanDto {
  const CheckInSyncScanDto({
    required this.scanId,
    required this.qrCode,
    required this.scannedAt,
  });

  final String scanId;
  final String qrCode;
  final DateTime scannedAt;

  Map<String, dynamic> toJson() => {
    'scanId': scanId,
    'qrCode': qrCode,
    'scannedAt': scannedAt.toUtc().toIso8601String(),
  };
}

/// One item of a `POST .../checkin/sync` response's `results`.
class CheckInSyncResultDto {
  const CheckInSyncResultDto({
    required this.scanId,
    required this.outcome,
    this.winningScannedAt,
    this.winningDeviceId,
    this.error,
  });

  factory CheckInSyncResultDto.fromJson(Map<String, dynamic> json) {
    final winningScannedAt = json['winningScannedAt'];
    return CheckInSyncResultDto(
      scanId: json['scanId'] as String,
      outcome: json['outcome'] as String? ?? '',
      winningScannedAt: winningScannedAt is String
          ? DateTime.tryParse(winningScannedAt)?.toLocal()
          : null,
      winningDeviceId: json['winningDeviceId'] as String?,
      error: json['error'] as String?,
    );
  }

  final String scanId;
  final String outcome;
  final DateTime? winningScannedAt;
  final String? winningDeviceId;
  final String? error;
}
