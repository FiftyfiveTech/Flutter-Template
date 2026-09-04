# Feature Spec: Refunds & Cancellations

Gap identified in PRD §7: "cannot legally sell tickets without it" — required for MVP despite no hours in the original estimate.

## 1. User Stories / Jobs-to-be-Done
* As a Host, I want to cancel an event and have every booked Member automatically and fully refunded, without manual per-booking intervention.
* As a Member, I want a clearly stated no-refund policy inside a defined cutoff window, shown before I complete my purchase.
* As Ops, I want to process exceptional/manual refunds outside the standard cancellation flow when a dispute requires it.

## 2. Data Entities & Screens
* **Entity**: extends `Booking` (refundStatus, refundedAt), extends `Payout` (adjustment entries for cancelled events).
* **Screens**: Host Cancel Event flow (`REFUND-01`), Cancellation-Terms Display (embedded in [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md)'s checkout, `REFUND-02`), Admin Refund Console (`REFUND-03`, part of [Admin Dashboard](./11-admin-dashboard.md)).

## 3. Dependencies
* Reverses bookings and releases held inventory in [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) — must call that feature's domain interface to reopen gender-pool capacity, not mutate its tables directly.
* Cancellation terms are authored in [Host Event Creation & Publishing](./host-app/02-host-event-publishing.md)'s event form and displayed at checkout.
* Manual/exceptional refunds are processed through [Admin Dashboard](./11-admin-dashboard.md).
* Refund/cancellation confirmations dispatched via [Notifications](./13-notifications.md).

## 4. Safety, Security & Regulatory Constraints
* Legally required for the pilot to run at all — selling tickets without a refund/cancellation mechanism is a compliance gap, not a nice-to-have.
* Host-initiated cancellation must trigger a **full**, automatic refund to every booked Member, executed atomically with the cancellation state change (no stuck "cancelled but unpaid" states).
* No-refund cutoff window must be disclosed to the Member clearly, pre-purchase, at checkout — not buried in terms.
* Refund transactions must be idempotent and reconciled against the payment gateway, mirroring the reconciliation requirements in [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md).
