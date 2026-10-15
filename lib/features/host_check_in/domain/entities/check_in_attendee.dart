/// One row of the door's guest list.
class CheckInAttendee {
  const CheckInAttendee({
    required this.bookingId,
    required this.userId,
    required this.firstName,
    this.photoUrl,
    this.ticketTypeName,
    this.checkedIn = false,
    this.scannedAt,
    this.noShow = false,
    this.isPendingSync = false,
  });

  final String bookingId;
  final String userId;
  final String firstName;
  final String? photoUrl;

  /// `null` when the list came from the offline manifest, which omits it.
  final String? ticketTypeName;
  final bool checkedIn;
  final DateTime? scannedAt;

  /// Server-derived: the event ended without this guest checking in.
  final bool noShow;

  /// Checked in on this device but not yet confirmed by the server.
  final bool isPendingSync;

  CheckInAttendee copyWith({
    bool? checkedIn,
    DateTime? scannedAt,
    bool? isPendingSync,
  }) {
    return CheckInAttendee(
      bookingId: bookingId,
      userId: userId,
      firstName: firstName,
      photoUrl: photoUrl,
      ticketTypeName: ticketTypeName,
      checkedIn: checkedIn ?? this.checkedIn,
      scannedAt: scannedAt ?? this.scannedAt,
      noShow: noShow,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }
}
