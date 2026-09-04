# Feature Spec: Audit Logging

Cross-cutting, append-only logging of every trust-critical decision. Source: PRD §6 — "the pilot's gates depend on this data being trustworthy."

## 1. User Stories / Jobs-to-be-Done
* As Ops, I want an immutable record of every verification decision, ratio-gate block, check-in, and payout, so I can defend the pilot's core claims (ratio held, verification enforced) with evidence.
* As Ops, I want to trace any admin action (see [Admin Dashboard](./11-admin-dashboard.md)) back to a specific actor and timestamp.

## 2. Data Entities & Screens
* **Entity**: `AuditLogEntry` (actorId, actorType: member/host/admin/system, action, targetType, targetId, timestamp, metadata).
* **Screens**: none end-user-facing; a read view lives inside [Admin Dashboard](./11-admin-dashboard.md) (`ADMIN-05`-adjacent).

## 3. Dependencies
* Implemented as a shared service in `lib/core/audit/` (or `lib/shared/`), called by [Identity Verification](./02-identity-verification.md) (verification decisions), [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) (ratio-gate blocks), [Host Night Operations](./host-app/03-host-night-operations.md) (check-ins, payouts), and [Admin Dashboard](./11-admin-dashboard.md) (all admin actions) — those features depend on this one's domain interface; this feature must depend on none of them.

## 4. Safety, Security & Regulatory Constraints
* Logs must be append-only / tamper-evident — no update or delete path for existing entries.
* Coverage must be complete for ratio-gate blocks specifically, since the hard male-ceiling claim ("no room above 60% male") is a product and potentially legal commitment measured against this data.
* Log entries containing personal data must be scoped/retained consistent with [DPDP Consent, Data Export & Deletion](./16-consent-privacy.md)'s DPDP determinations.
