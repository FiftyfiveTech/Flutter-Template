import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/check_in_outcome.dart';
import '../../domain/entities/check_in_result.dart';

/// `9:05 PM`
String formatCheckInTime(DateTime time) {
  final local = time.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

enum CheckInTone { success, warning, error }

extension CheckInToneColor on CheckInTone {
  Color colorIn(AppColors colors) => switch (this) {
    CheckInTone.success => colors.statusSuccess,
    CheckInTone.warning => colors.statusWarning,
    CheckInTone.error => colors.statusError,
  };

  IconData get icon => switch (this) {
    CheckInTone.success => Icons.check_circle,
    CheckInTone.warning => Icons.error,
    CheckInTone.error => Icons.cancel,
  };
}

/// Door-facing copy for each outcome: a short headline readable at a
/// glance, plus a line telling the host what to do.
class CheckInOutcomeCopy {
  const CheckInOutcomeCopy({
    required this.title,
    required this.detail,
    required this.tone,
  });

  final String title;
  final String detail;
  final CheckInTone tone;

  factory CheckInOutcomeCopy.forResult(CheckInResult result) {
    final scannedAt = result.scannedAt;
    switch (result.outcome) {
      case CheckInOutcome.accepted:
        return CheckInOutcomeCopy(
          title: 'Checked in',
          detail: result.isOffline
              ? 'Saved on this phone. It syncs when you reconnect.'
              : 'Match the face to the photo, then let them in.',
          tone: CheckInTone.success,
        );
      case CheckInOutcome.alreadyCheckedIn:
        return CheckInOutcomeCopy(
          title: 'Already checked in',
          detail: scannedAt != null
              ? 'This ticket was used at ${formatCheckInTime(scannedAt)}. '
                    "Don't let it in twice."
              : "This ticket was already used. Don't let it in twice.",
          tone: CheckInTone.warning,
        );
      case CheckInOutcome.invalidTicket:
        return CheckInOutcomeCopy(
          title: 'Invalid ticket',
          detail:
              result.message ??
              "This QR isn't a valid After Hours ticket. Ask the guest to "
                  'open the ticket in the app.',
          tone: CheckInTone.error,
        );
      case CheckInOutcome.wrongEvent:
        return CheckInOutcomeCopy(
          title: 'Wrong event',
          detail: result.message ?? 'This ticket is for a different event.',
          tone: CheckInTone.error,
        );
      case CheckInOutcome.noBooking:
        return CheckInOutcomeCopy(
          title: 'No booking found',
          detail:
              result.message ??
              "There's no booking for this ticket. It may have been "
                  'cancelled or refunded.',
          tone: CheckInTone.error,
        );
      case CheckInOutcome.bookingNotConfirmed:
        return CheckInOutcomeCopy(
          title: 'Booking not confirmed',
          detail:
              result.message ??
              "This booking's payment hasn't gone through yet.",
          tone: CheckInTone.error,
        );
      case CheckInOutcome.rejected:
        return CheckInOutcomeCopy(
          title: "Couldn't check in",
          detail: result.message ?? 'Something went wrong. Try again.',
          tone: CheckInTone.error,
        );
      case CheckInOutcome.notOnGuestList:
        return const CheckInOutcomeCopy(
          title: 'Not on the offline list',
          detail:
              "You're offline and this ticket isn't on the guest list "
              'downloaded to this phone. It may be a late booking, or not '
              'a real ticket.',
          tone: CheckInTone.warning,
        );
      case CheckInOutcome.guestListExpired:
        return const CheckInOutcomeCopy(
          title: "Can't verify offline",
          detail:
              "You're offline and the guest list on this phone has "
              'expired. Reconnect to refresh it.',
          tone: CheckInTone.warning,
        );
      case CheckInOutcome.noGuestList:
        return const CheckInOutcomeCopy(
          title: "Can't verify offline",
          detail:
              "You're offline and no guest list has been downloaded to "
              'this phone yet. Reconnect once to download it.',
          tone: CheckInTone.warning,
        );
    }
  }
}

/// Short label for a sync conflict row.
String conflictReason(CheckInOutcome outcome) => switch (outcome) {
  CheckInOutcome.alreadyCheckedIn => 'Already checked in on another device',
  CheckInOutcome.invalidTicket => 'Invalid ticket',
  CheckInOutcome.wrongEvent => 'Ticket for a different event',
  CheckInOutcome.noBooking => 'No booking found',
  CheckInOutcome.bookingNotConfirmed => 'Booking not confirmed',
  _ => 'Rejected by the server',
};
