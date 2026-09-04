# Feature Spec: Waitlist Mechanics

Gap identified in PRD §7 ("implied by gender-pool sellouts and women-first seeding") — required for MVP, not in the original hour estimate.

## 1. User Stories / Jobs-to-be-Done
* As a male Member blocked by the hard ratio ceiling, I want to join a waitlist so I'm notified automatically when a seat frees up.
* As a Member on the waitlist, I want to be released fairly (FIFO, or per the host's configured release schedule) as male inventory opens up from female sales or a host-configured release schedule.
* As a Host, I want to configure a release schedule (e.g., hold back male inventory until the female pool crosses a threshold) to support a women-first seeding strategy.
* Acceptance: no member is left believing the room is "sold out" when a waitlist path exists; waitlist releases happen automatically without manual ops intervention.

## 2. Data Entities & Screens
* **Entity**: `WaitlistEntry` (eventId, userId, gender, joinedAt, status: `waiting | released | expired`).
* **Screens**: Waitlist Join Confirmation (`WAIT-01`), Waitlist Status (in "My Tickets", `WAIT-02`).

## 3. Dependencies
* Primary trigger and consumer relationship with [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) — waitlist release is driven by that feature's live male-seat recomputation; this feature must call its domain interface for "seats freed" events rather than duplicating ratio math.
* Join entry point surfaced from [Event Discovery & Browsing](./03-event-discovery.md)'s sold-out-for-gender state.
* Release/booking-window notifications sent via [Notifications](./13-notifications.md).
* Host-configured release schedule is authored in [Host Event Creation & Publishing](./host-app/02-host-event-publishing.md)'s event form and read (not owned) here.

## 4. Safety, Security & Regulatory Constraints
* Waitlist is, by design, effectively a male-side-only mechanism (female side is uncapped, capacity-bound) — copy and UX must not imply symmetric fairness between genders.
* Release ordering (FIFO vs. host-configured schedule) must be deterministic and auditable via [Audit Logging](./14-audit-logging.md), since it directly affects who gets a scarce seat.
* A released waitlist seat must still pass through the same transactional, race-safe hold/decrement logic as a normal purchase in [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) — no bypass path that could cause overselling.
