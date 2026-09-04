# Feature Spec: Admin Dashboard

Web-only ops surface for verification review, host approval, refunds, and incident handling. Named as an assumption throughout the PRD but carries **no hours in the current estimate** — flagged in §7 as needing separate estimation (~40–60 backend/web hours) before sprint planning.

## 1. User Stories / Jobs-to-be-Done
* As After Hours Ops, I want a queue of member verifications that were rejected or exhausted their one retry, so I can manually decide pass/fail.
* As Ops, I want to review Host onboarding documents and licences (business registration, PAN, FSSAI, excise) and approve or reject them.
* As Ops, I want to approve or reject a Host's first three events before they can auto-publish.
* As Ops, I want visibility into ratio-skew flags (rooms tagged as female-skewed past 60%) for pilot reporting, without any ability to override the hard male ceiling.
* As Ops, I want to process refunds/cancellations and handle escalated reports/blocks from the Chat feature.
* As Ops, I want to perform the one legitimate admin override in the system: changing a Member's `gender` field after it's been set once.
* Acceptance: (unestimated — see §7 of the PRD) all admin actions are traceable to a specific ops user and timestamp.

## 2. Data Entities & Screens
* Touches `User`, `HostAccount`, `Licence`, `Event`, `Booking`, `Payout`, `Report` — read broadly, with narrow, purpose-built write use cases (e.g., "approve host document," "process refund," "change member gender") rather than generic CRUD.
* **Screens**: Verification Queue (`ADMIN-01`), Host Review Queue (`ADMIN-02`), Event Approval Queue (`ADMIN-03`), Refund/Incident Console (`ADMIN-04`), Ratio/Skew Report (`ADMIN-05`).

## 3. Dependencies
* Consumes the **domain repository interfaces** of [Identity Verification](./02-identity-verification.md), [Host Onboarding & Licence Verification](./host-app/01-host-onboarding.md), [Host Event Creation & Publishing](./host-app/02-host-event-publishing.md), [Refunds & Cancellations](./12-refunds-cancellations.md), [Chat & Safety Controls](./07-chat-safety.md), and [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) — per the cross-feature boundary rule, this app must never import those features' `presentation/` or `data/` internals directly.
* Writes exclusively through [Audit Logging](./14-audit-logging.md) for every decision made.
* Reads aggregated funnel/ratio/repeat metrics from [Analytics Instrumentation](./15-analytics-instrumentation.md).

## 4. Safety, Security & Regulatory Constraints
* Web-only, RBAC-restricted to After Hours ops staff — must not share auth scope with Member or Host accounts ([Platform Foundation](./17-platform-foundation.md)).
* Every admin action (verification decision, host approval, refund, gender change) must be audit-logged with actor, timestamp, and target.
* Must **not** provide any path to override the hard male ratio ceiling in [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) or bypass `CheckIn` gating in [Host Night Operations](./host-app/03-host-night-operations.md) — both are explicitly "no exceptions, no manual admin override in MVP."
* Currently unestimated: flag to stakeholders as a scope/budget risk before committing to a pilot timeline.
