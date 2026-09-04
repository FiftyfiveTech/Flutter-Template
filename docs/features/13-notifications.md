# Feature Spec: Notifications

Shared push-notification dispatch used across nearly every other feature. Source: PRD §6.

## 1. User Stories / Jobs-to-be-Done
* As a Member, I want to be pushed on: verification decision, booking confirmation, event reminders (24h and 2h before), matching pool open, new match, new message.
* As a Host, I want to be pushed on: host verification decision, event approval decision, licence expiry warnings (30/7 days).
* As any user, I want notifications to be timely and never leak information I shouldn't see (e.g., no notification should reveal another attendee's identity in a block/report context).

## 2. Data Entities & Screens
* **Entity**: `DeviceToken` (userId/hostAccountId, platform, token), `NotificationLog` (recipientId, type, payload, sentAt).
* **Screens**: none directly — system-level push; an optional in-app notification center is out of scope unless separately requested.

## 3. Dependencies
* Exposed as a shared dispatch interface in `lib/core/notifications/` (or `lib/shared/`) — consumed by [Identity Verification](./02-identity-verification.md), [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md), [Waitlist Mechanics](./05-waitlist.md), [Post-Event Matching](./06-post-event-matching.md), [Chat & Safety Controls](./07-chat-safety.md), [Host Onboarding & Licence Verification](./host-app/01-host-onboarding.md), [Host Event Creation & Publishing](./host-app/02-host-event-publishing.md), [Refunds & Cancellations](./12-refunds-cancellations.md). Per the cross-feature boundary rule, those features call this shared interface directly rather than importing each other.
* Uses FCM/APNs via [Platform Foundation](./17-platform-foundation.md).

## 4. Safety, Security & Regulatory Constraints
* Device token storage must respect the consent scope captured in [DPDP Consent, Data Export & Deletion](./16-consent-privacy.md).
* Notification payloads must never leak safety-sensitive information: no female-skew warnings to Members ([Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md)), no other-party identity details in block/report-adjacent notifications ([Chat & Safety Controls](./07-chat-safety.md)).
* Delivery of the "booking confirmation" push must only fire after gateway-confirmed payment, matching the confirmation rule in [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) — never on optimistic client state.
