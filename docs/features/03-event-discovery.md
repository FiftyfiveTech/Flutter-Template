# Feature Spec: Event Discovery & Browsing

List, filter, search, and view events. Source: PRD §4.3.

## 1. User Stories / Jobs-to-be-Done
* As a Member, I want to browse upcoming events in my city as a list or grid, sorted by date.
* As a Member, I want to filter by date range, price band, neighbourhood, format, and host, and search by event title or host name.
* As a Member, I want an event detail page showing host name and verification badge, venue area (not exact address until booked), date/time, format, price, **seats remaining for my gender**, the ratio policy statement, and cancellation terms.
* As a Member, I want a clearly different "sold out for your gender" state (with a waitlist option) versus "sold out entirely," so I'm not misled about my odds.
* Acceptance: a user in Indiranagar can find and open a relevant event in under three taps from home.

## 2. Data Entities & Screens
* **Entity**: `Event`, `TicketType` (read-only consumption in this feature; both are owned/written by [Host Event Creation & Publishing](./host-app/02-host-event-publishing.md) and [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md)).
* **Screens**: Event List/Grid (`DISC-01`), Filter & Search Sheet (`DISC-02`), Event Detail (`DISC-03`).

## 3. Dependencies
* Reads live per-gender seat availability from [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md)'s domain repository interface — this feature must not compute ratio logic itself.
* Reads host name/verification badge and licence status from [Host Onboarding & Licence Verification](./host-app/01-host-onboarding.md)'s domain interface, and event content from [Host Event Creation & Publishing](./host-app/02-host-event-publishing.md)'s domain interface.
* Sold-out-for-gender state links into [Waitlist Mechanics](./05-waitlist.md) (join action).
* Consumes [Platform Foundation](./17-platform-foundation.md) for the base API client / query layer.

## 4. Safety, Security & Regulatory Constraints
* Exact venue address must remain hidden until a booking is confirmed — released only post-purchase, a privacy/safety control for attendees.
* The host verification badge must reflect current verification and licence status, not a cached/stale flag (a lapsed-licence venue must not display as trustworthy).
* No member-facing signal may reveal ratio skew details beyond generic "seats remaining for your gender" — no exposing the female soft-ceiling mechanics per [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md).
