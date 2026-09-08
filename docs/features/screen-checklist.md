# Screen Checklist (derived from feature specs)

Master list of every screen ID referenced across `docs/features/`. Use this to audit a Claude Design project feature-by-feature: check off each ID that exists, and flag ones that exist but don't match the spec's stated content requirements (see "Correctness check" column).

Legend: `[ ]` not yet verified · mark `[x]` once confirmed present and correct, `[!]` if present but wrong.

## End-User App

### 01 — Member Registration & Profile
- [ ] `REG-01` Phone Entry
- [ ] `REG-02` OTP Confirmation
- [ ] `REG-03` Profile Setup — must collect first name, DOB, gender, city, one photo
- [ ] `REG-04` Consent Capture (embedded in signup) — must show versioned/timestamped DPDP consent copy, not a generic checkbox

### 02 — Identity Verification
- [ ] `VER-01` Guided Capture — liveness selfie + government ID scan
- [ ] `VER-02` Verification Status/Pending — must reflect live state (`pending → verified/rejected`), not a static spinner
- [ ] `VER-03` Rejection & Retry — must show rejection reason + a single retry action, then hand off to admin queue messaging

### 03 — Event Discovery & Browsing
- [ ] `DISC-01` Event List/Grid
- [ ] `DISC-02` Filter & Search Sheet — date range, price band, neighbourhood, format, host, text search
- [ ] `DISC-03` Event Detail — must show host verification badge, venue **area only** (no exact address pre-booking), seats remaining **for the user's gender**, ratio policy statement, cancellation terms, and a distinct sold-out-for-gender vs. sold-out-entirely state with waitlist CTA

### 04 — Booking, Ratio Gating & Payments
- [ ] `BOOK-01` Checkout / Seat Hold — must show the 10-minute hold countdown
- [ ] `BOOK-02` UPI Payment
- [ ] `BOOK-03` Payment Status — must not show "confirmed" before gateway webhook success (no optimistic client-only success state)
- [ ] `BOOK-04` Ticket/QR Display — signed, single-use QR, offline-viewable

### 05 — Waitlist Mechanics
- [ ] `WAIT-01` Waitlist Join Confirmation
- [ ] `WAIT-02` Waitlist Status (in "My Tickets")

### 06 — Post-Event Matching
- [ ] `MATCH-01` Matching Pool / Card Swipe — card shows first name, age, photo, one-line prompt only (no last name/contact/location/cross-event history); visible 72h countdown
- [ ] `MATCH-02` Match List — must show which **event** each match came from

### 07 — Chat & Safety Controls
- [ ] `CHAT-01` Chat Thread — visible countdown from thread open; read-only (no send) after expiry, not deleted
- [ ] `CHAT-02` Match List w/ Unread Indicators
- [ ] `CHAT-03` Block/Report/Unmatch Confirmation Sheets — block must be framed as silent to the other party

## Host App (separate app — `docs/features/host-app/`)

### 08 — Host Onboarding & Licence Verification
- [x] `HOST-ON-01` Host Signup
- [x] `HOST-ON-02` host_type Selection
- [x] `HOST-ON-03` Document Upload — must render **conditionally** per host_type (venue gets FSSAI/excise fields, others don't)
- [ ] `HOST-ON-04` Verification Status

### 09 — Host Event Creation & Publishing
- [ ] `HOST-EVT-01` Event Form (Create/Edit) — must include ratio target/release schedule fields, and lock price/date once first ticket sells
- [ ] `HOST-EVT-02` Event List (Host)
- [ ] `HOST-EVT-03` Submission/Approval Status

### 10 — Host Night Operations
- [ ] `HOST-OPS-01` Live Dashboard — sold-by-gender vs. target, live ratio, male seats remaining vs. locked, non-blocking skew warning past 60% female
- [ ] `HOST-OPS-02` QR Scanner — valid/invalid/already-used states, manual name-search fallback, must work offline
- [ ] `HOST-OPS-03` Attendee List — check-in status + no-show flags
- [ ] `HOST-OPS-04` Payout View — gross/fee/net/status; must **not** show F&B rebate for venue hosts

## Admin & Platform

### 11 — Admin Dashboard
- [ ] `ADMIN-01` Verification Queue
- [ ] `ADMIN-02` Host Review Queue
- [ ] `ADMIN-03` Event Approval Queue
- [ ] `ADMIN-04` Refund/Incident Console
- [ ] `ADMIN-05` Ratio/Skew Report (also hosts the audit-log read view)

### 12 — Refunds & Cancellations
- [ ] `REFUND-01` Host Cancel Event flow
- [ ] `REFUND-02` Cancellation-Terms Display (embedded in `BOOK-01` checkout — verify it appears there, not just standalone)
- [ ] `REFUND-03` Admin Refund Console (part of `ADMIN-04`)

### 16 — DPDP Consent, Data Export & Deletion
- [ ] `PRIV-01` Privacy Settings — Export/Delete Request
- [ ] `PRIV-02` Admin Fulfillment Queue (part of Admin Dashboard)

### No dedicated screens (infra/cross-cutting — verify via behavior, not a screen)
- 13 — Notifications (push payloads only)
- 14 — Audit Logging (folded into `ADMIN-05`)
- 15 — Analytics Instrumentation (no UI)
- 17 — Platform Foundation (no UI)

---

**Total standalone screen IDs: 34** (across 12 screen-bearing features).

## How to run the audit once Claude Design is connected
1. `list_files` on the target design-system project to get the actual file/screen list.
2. Diff its names/paths against the IDs above — anything in the spec with no corresponding design file is a gap; anything in the design project with no spec entry is either undocumented scope creep or a missing spec.
3. For screens flagged with a "must" clause above, `get_file` the specific screen and check its content against that clause — that's the "correctness" pass, not just existence.
