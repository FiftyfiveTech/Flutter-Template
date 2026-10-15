/// What the door should do with a ticket.
///
/// Mirrors the backend's check-in outcomes (`valid`/`accepted`,
/// `already_checked_in`, `invalid_signature`, `wrong_event`, `no_booking`,
/// `booking_not_confirmed`), plus three offline-only outcomes for a scan
/// that couldn't be verified against a usable downloaded guest list.
enum CheckInOutcome {
  accepted,
  alreadyCheckedIn,
  invalidTicket,
  wrongEvent,
  noBooking,
  bookingNotConfirmed,

  /// Any other server rejection — the result's message says why.
  rejected,

  /// Offline, and the QR's hash isn't in the downloaded guest list (e.g. a
  /// booking made after the list was downloaded, or a forged ticket).
  notOnGuestList,

  /// Offline, and the downloaded guest list is past its `expiresAt`.
  guestListExpired,

  /// Offline, and no guest list was ever downloaded on this device.
  noGuestList;

  bool get isAdmitted => this == CheckInOutcome.accepted;

  /// Offline outcomes where the host may still queue the raw QR for the
  /// server to verify on sync. The server stays the only gate into
  /// matching, so a forged ticket is still rejected there.
  bool get canQueueForVerification =>
      this == CheckInOutcome.notOnGuestList ||
      this == CheckInOutcome.guestListExpired ||
      this == CheckInOutcome.noGuestList;
}
