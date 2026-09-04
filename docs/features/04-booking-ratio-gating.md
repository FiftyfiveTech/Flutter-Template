# Feature Spec: Booking, Ratio Gating & Payments

The load-bearing feature of the product: gender-ratio-gated ticket sales with UPI payment and QR ticket issuance. Source: PRD §4.4.

## 1. User Stories / Jobs-to-be-Done
* As a verified Member, I want to buy a seat via UPI and receive a signed, single-use QR ticket on confirmed payment.
* As a Member, if I'm male and the room has hit its 60% male ceiling, I want to be blocked outright with an honest message and a waitlist option — this is a hard, no-exceptions gate.
* As a female Member, I never want to be told the room has "too many women" even if the female share exceeds 60% — that ceiling is soft and invisible to me.
* As a Member, I want my seat held for a bounded window during checkout so a stalled payment doesn't oversell the room.
* As a Member, I want my booking confirmed only once payment truly succeeds (not on an optimistic client callback), so I never hold a "ghost" ticket.
* Acceptance: zero oversold gender pools across the pilot; payment-to-ticket latency under 10s at p95.

## 2. Data Entities & Screens
* **Entity**: `Booking`, `TicketType`, `Event` (gender-cap counters, recomputed live against sold volume, not fixed at publish time), `Payout`-adjacent `Order`/payment record, `QRTicket` (signed, single-use, tied to booking + user).
* **Screens**: Checkout / Seat Hold (`BOOK-01`), UPI Payment (`BOOK-02`), Payment Status (`BOOK-03`), Ticket/QR Display (`BOOK-04`).

## 3. Dependencies
* Calls [Identity Verification](./02-identity-verification.md)'s domain interface (`isVerified`) to gate checkout — verification is mandatory before payment.
* Entry point from [Event Discovery & Browsing](./03-event-discovery.md) (event detail → book).
* Triggers [Waitlist Mechanics](./05-waitlist.md) release when male seats free up (soft-ceiling female sales growing effective male allocation).
* Its `Booking`/`CheckIn`-eligible QR is consumed by [Host Night Operations](./host-app/03-host-night-operations.md) at the door; this feature never imports that feature's scanner code, only exposes the ticket-validation domain contract.
* Reversed by [Refunds & Cancellations](./12-refunds-cancellations.md) on host-initiated cancellation.
* Every ratio-gate block is logged via [Audit Logging](./14-audit-logging.md); funnel/ratio deltas feed [Analytics Instrumentation](./15-analytics-instrumentation.md).
* Uses the licensed UPI gateway partner and [Platform Foundation](./17-platform-foundation.md)'s base network layer.

## 4. Safety, Security & Regulatory Constraints
* **Directional asymmetry (decided):** male ceiling is hard (blocks purchase outright at 60% male of sold seats); female ceiling is soft (purchase continues past 60% female; only a non-blocking host/ops-facing warning, never member-facing).
* Ratio band is enforced continuously against *current* sold inventory, not checked at the end — a gender unblocks automatically as the other side fills.
* Small-numbers guard: band is not enforced below a floor of 10 sold seats.
* Male inventory must be recomputed live against sold volume (not a static pool at publish time), because the soft female ceiling grows effective male allocation.
* Inventory decrements must be transactional and race-safe; a seat is held for a bounded 10-minute window during checkout and released on failure/timeout — overselling a gender pool breaks the core product promise.
* Booking is confirmed **only** on the gateway's success webhook, never on a client-side success callback. Order creation must be idempotent, with a reconciliation job for pending/ambiguous transactions.
* Every ratio-gate block must be audit-logged (pre-door/at-door ratio measurement depends on this data being trustworthy).
