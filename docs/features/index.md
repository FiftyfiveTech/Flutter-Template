# Features Specification Index

Feature areas parsed from `docs/After_Hours_MVP_PRD.pdf` (v1.0, Sept 2026). Each spec covers user stories, data entities/screens, cross-feature dependencies, and safety/security/regulatory constraints.

The PRD defines three surfaces on one shared backend (§2). The **Host App is a separate mobile app from the End-User App**, so its specs live in their own [host-app/](./host-app/index.md) subfolder rather than being numbered inline with End-User features — a Host feature must never be scaffolded under the same `lib/features/` namespace as an End-User one, and vice versa.

## End-User App
1. [Member Registration & Profile](./01-member-registration.md) — phone-OTP signup, minimum profile, age gate, DPDP consent capture.
2. [Identity Verification](./02-identity-verification.md) — selfie/ID verification via vendor SDK, gates checkout.
3. [Event Discovery & Browsing](./03-event-discovery.md) — list/grid, filters, search, event detail.
4. [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) — the load-bearing feature: asymmetric gender-ratio gate, UPI payment, QR ticket.
5. [Waitlist Mechanics](./05-waitlist.md) — male-side waitlist and release, PRD §7 gap.
6. [Post-Event Matching](./06-post-event-matching.md) — 72h swipe pool gated strictly by CheckIn.
7. [Chat & Safety Controls](./07-chat-safety.md) — 72h match chat, block/report/unmatch.

## Host App (separate app — see [host-app/index.md](./host-app/index.md))
8. [Host Onboarding & Licence Verification](./host-app/01-host-onboarding.md) — host_type-conditional documents, excise/FSSAI expiry.
9. [Host Event Creation & Publishing](./host-app/02-host-event-publishing.md) — event form, draft→submit→published lifecycle.
10. [Host Night Operations](./host-app/03-host-night-operations.md) — dashboard, offline QR check-in, payouts.

## Admin & Platform
11. [Admin Dashboard](./11-admin-dashboard.md) — verification/host/event review, refunds, incident handling. Currently unestimated (PRD §7).
12. [Refunds & Cancellations](./12-refunds-cancellations.md) — host-initiated auto-refund, no-refund cutoff. PRD §7 gap, legally required.
13. [Notifications](./13-notifications.md) — shared push dispatch consumed by nearly every feature.
14. [Audit Logging](./14-audit-logging.md) — append-only log backing every ratio-gate, verification, check-in, and payout claim.
15. [Analytics Instrumentation](./15-analytics-instrumentation.md) — funnel/ratio/repeat metrics behind the 90-day pilot gates. PRD §7 gap.
16. [DPDP Consent, Data Export & Deletion](./16-consent-privacy.md) — pre-build legal gate; blocks ID-image and chat retention decisions.
17. [Platform Foundation](./17-platform-foundation.md) — shared backend, RBAC, environments; depends on nothing, everything depends on it.
