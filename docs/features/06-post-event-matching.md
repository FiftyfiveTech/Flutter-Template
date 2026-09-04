# Feature Spec: Post-Event Matching ("The Morning After")

Swipe-based matching restricted to an event's checked-in attendees. Source: PRD §4.5.

## 1. User Stories / Jobs-to-be-Done
* As a checked-in attendee, I want the matching pool to open at 09:00 the morning after the event and stay open for 72 hours, with a visible countdown.
* As a Member who hasn't opened the pool, I want reminder pushes at 24 hours remaining, and a second reminder at 12 hours if I still haven't opened it.
* As a Member, I want to see only first name, age, photo, and a one-line prompt answer for other checked-in attendees — no last names, contact details, cross-event history, or location.
* As a Member, I want a per-event cap of 5 right-swipes so my selection stays deliberate.
* As a Member, I want a mutual right-swipe to create a Match, while non-mutual swipes are never revealed to anyone (counts only, never names).
* As a Member, I want to opt out of a given event's pool at check-in or any time before the pool opens.
* As a Member with a match made in the pool's final hour, I still want the full 72-hour chat window, and I want my match list to clearly show which event each match came from.
* Acceptance: no user can view another user's card without both parties holding a check-in record for the same event.

## 2. Data Entities & Screens
* **Entity**: `MatchSelection` (eventId, fromUserId, toUserId, direction, createdAt), `Match` (eventId, userAId, userBId, createdAt); reads `CheckIn` (owned by [Host Night Operations](./host-app/03-host-night-operations.md)).
* **Screens**: Matching Pool / Card Swipe (`MATCH-01`), Match List (`MATCH-02`, shows originating event per match).

## 3. Dependencies
* Eligibility is strictly gated by `CheckIn` records owned by [Host Night Operations](./host-app/03-host-night-operations.md) — this feature must consume that feature's **domain** repository interface (`isCheckedIn(userId, eventId)`) only; it must never import that feature's scanner/presentation code.
* Reads profile fields (first name, age, photo) from [Member Registration & Profile](./01-member-registration.md)'s domain interface.
* A mutual `Match` triggers thread creation in [Chat & Safety Controls](./07-chat-safety.md).
* Reminder/countdown pushes dispatched via [Notifications](./13-notifications.md).
* Match/message counts attributed to originating event feed [Analytics Instrumentation](./15-analytics-instrumentation.md) (not calendar week).

## 4. Safety, Security & Regulatory Constraints
* Eligibility check (`CheckIn` for that event, for both parties) must be enforced server-side on every card fetch — a purchased-but-not-scanned-in ticket must appear to nobody and see nobody, with **no admin override** in MVP.
* Non-mutual selections must never be surfaced by name to either party — counts only, per the deck's explicit safety commitment.
* No last names, contact details, cross-event history, or location on cards.
* Per-event right-swipe cap (default 5) must be enforced server-side, not just in the client UI.
* Opt-out must be honored at any point up to pool opening and reflected immediately in matching eligibility.
