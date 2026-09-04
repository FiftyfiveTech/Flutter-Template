# Feature Spec: Host Night Operations — Dashboard, Check-in & Payouts

Running the live event: real-time dashboard, offline-capable QR check-in, and payout tracking. Source: PRD §5.3.

## 1. User Stories / Jobs-to-be-Done
* As a Host, I want a live dashboard showing tickets sold by gender against target, revenue to date, live ratio, male seats remaining vs. currently locked, and a countdown to doors — with a non-blocking skew warning once the room passes 60% female.
* As a Host, I want a QR check-in scanner with immediate valid/invalid/already-used feedback and a manual name-search fallback, that works fully offline with a local queue and syncs on reconnect.
* As a Host, I want an attendee list with check-in status and no-show flags.
* As a Host, I want a payout view showing gross ticket value, the 20% platform fee, net payable, and status (pending/processing/paid).
* As a Venue Host, I want to see the same ticket payout view as any other host — with my F&B rebate explicitly not shown here, since it's settled off-platform during the pilot.
* Acceptance: a host can check in 64 attendees in under 12 minutes with one scanner device.

## 2. Data Entities & Screens
* **Entity**: `CheckIn` (bookingId, userId, eventId, scannedAt, method: qr/manual), `Payout` (eventId, hostAccountId, gross, platformFee, net, status).
* **Screens**: Live Dashboard (`HOST-OPS-01`), QR Scanner (`HOST-OPS-02`), Attendee List (`HOST-OPS-03`), Payout View (`HOST-OPS-04`).

## 3. Dependencies
* Validates tickets against [Booking, Ratio Gating & Payments](../04-booking-ratio-gating.md)'s signed QR / `Booking` domain interface — must verify signature and single-use status, not just decode the QR payload.
* `CheckIn` records created here are the sole eligibility source consumed by [Post-Event Matching](../06-post-event-matching.md) via that feature's domain interface — this feature must not reach into matching's data layer, and vice versa.
* Payout figures depend on [Host Onboarding & Licence Verification](./01-host-onboarding.md)'s validated bank/UPI details.
* Skew warnings and ratio stats surface to [Admin Dashboard](../11-admin-dashboard.md) for pilot reporting.
* Every check-in and payout event is written via [Audit Logging](../14-audit-logging.md).
* Payout batch execution is ops-triggered via the payment gateway ([Platform Foundation](../17-platform-foundation.md)), T+2 after the event.

## 4. Safety, Security & Regulatory Constraints
* `CheckIn` is the system's central gate: **no scanned QR at the venue, no entry into the event's matching pool — with no exceptions and no manual admin override in MVP.**
* Scanner must work fully offline with a local queue and sync-on-reconnect; venue wifi must never be a dependency the door relies on.
* QR must be validated as signed and single-use to prevent duplicate entry or forged tickets.
* Female-skew warning is non-blocking and host/ops-facing only — never surfaced to members (see [Booking, Ratio Gating & Payments](../04-booking-ratio-gating.md)).
* Venue Host F&B rebate must not appear in the payout view — it is a manual, off-platform commercial agreement during the pilot, and the dashboard must not imply the platform settles it.
* Every check-in and payout transition must be audit-logged — the pilot's ratio-gate and payout trust claims depend on this data being complete.
