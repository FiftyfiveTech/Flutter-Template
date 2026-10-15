import '../../domain/entities/check_in_attendee.dart';

/// One item of `GET .../attendees`.
class CheckInAttendeeDto {
  const CheckInAttendeeDto({
    required this.bookingId,
    required this.userId,
    required this.firstName,
    required this.checkedIn,
    required this.noShow,
    this.photoUrl,
    this.ticketTypeName,
    this.scannedAt,
  });

  factory CheckInAttendeeDto.fromJson(Map<String, dynamic> json) {
    final scannedAt = json['scannedAt'];
    return CheckInAttendeeDto(
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      ticketTypeName: json['ticketTypeName'] as String?,
      checkedIn: json['checkedIn'] as bool? ?? false,
      scannedAt: scannedAt is String
          ? DateTime.tryParse(scannedAt)?.toLocal()
          : null,
      noShow: json['noShow'] as bool? ?? false,
    );
  }

  final String bookingId;
  final String userId;
  final String firstName;
  final String? photoUrl;
  final String? ticketTypeName;
  final bool checkedIn;
  final DateTime? scannedAt;
  final bool noShow;

  CheckInAttendee toDomain() {
    return CheckInAttendee(
      bookingId: bookingId,
      userId: userId,
      firstName: firstName,
      photoUrl: photoUrl,
      ticketTypeName: ticketTypeName,
      checkedIn: checkedIn,
      scannedAt: scannedAt,
      noShow: noShow,
    );
  }
}
