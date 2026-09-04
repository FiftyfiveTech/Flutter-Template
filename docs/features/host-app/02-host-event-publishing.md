# Feature Spec: Host Event Creation & Publishing

Event authoring and the draft → submit → published lifecycle. Source: PRD §5.2.

## 1. User Stories / Jobs-to-be-Done
* As a Host, I want to create an event with title, description, format, date/time, venue and address, capacity, ratio target and release schedule, ticket price(s), cancellation terms, and cover media.
* As a Host, I want my first three events to route through admin approval, and after that, to auto-publish with post-hoc review.
* As a Host, I want price and date locked once the first ticket sells, while capacity can increase but never fall below tickets already sold.

## 2. Data Entities & Screens
* **Entity**: `Event` (title, description, format, dateTime, venue, address, capacity, ratioTarget, releaseSchedule, cancellationTerms, coverMediaUrl, lifecycleState: draft/submitted/published), `TicketType` (price tiers).
* **Screens**: Event Form — Create/Edit (`HOST-EVT-01`), Event List (Host) (`HOST-EVT-02`), Submission/Approval Status (`HOST-EVT-03`).

## 3. Dependencies
* Publish action is gated by [Host Onboarding & Licence Verification](./01-host-onboarding.md)'s domain interface (`isVerified`, `hasValidLicence`) — must block publish, not just warn, if either check fails.
* First-three-events approval flow escalates into [Admin Dashboard](../11-admin-dashboard.md)'s event approval queue.
* Ratio target and release schedule authored here are read (not owned) by [Booking, Ratio Gating & Payments](../04-booking-ratio-gating.md) and [Waitlist Mechanics](../05-waitlist.md) at purchase/waitlist time.
* Event content is read by [Event Discovery & Browsing](../03-event-discovery.md) for browsing/search.
* Cancellation terms authored here are enforced by [Refunds & Cancellations](../12-refunds-cancellations.md).

## 4. Safety, Security & Regulatory Constraints
* Publish must be blocked server-side (not just hidden in UI) for unverified hosts or hosts with a lapsed excise/FSSAI licence.
* Edit rules must be enforced server-side: price and date lock once the first ticket sells; capacity may only increase, never drop below tickets already sold — prevents bait-and-switch against buyers holding a `Booking`.
* Ratio target must default to 50:50 with a ±10pt band; hosts may tighten the band but the system must reject attempts to widen it beyond the platform default.
