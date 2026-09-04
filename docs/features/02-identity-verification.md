# Feature Spec: Identity Verification

Selfie/liveness + government-ID verification via a third-party vendor. This is the platform's core trust differentiator. Source: PRD §4.2.

## 1. User Stories / Jobs-to-be-Done
* As a Member, I want to complete a guided liveness selfie and ID capture so the platform can confirm I'm a real, age-eligible person.
* As a Member, I want to see my verification state (`unverified → pending → verified | rejected`) update live, without needing to refresh manually.
* As a Member, if I'm rejected, I want to see the reason and get exactly one retry before it escalates to a human review queue.
* As a Member, I want to browse events freely while unverified, but understand I must be verified before I can pay — this should never be softened for conversion.
* As a Member, once verified, I never want to be asked to verify again.
* Acceptance: median verification decision returns in under 3 minutes.

## 2. Data Entities & Screens
* **Entity**: `VerificationRecord` (userId, status, vendorReferenceId, derivedAge, rejectionReason, decidedAt) — note raw ID images are **not** part of this entity; see §4.
* **Screens**: Guided Capture (`VER-01`: liveness selfie + ID scan), Verification Status/Pending (`VER-02`), Rejection & Retry (`VER-03`).

## 3. Dependencies
* Extends [Member Registration & Profile](./01-member-registration.md)'s `User` — consumes the domain repository interface only, does not read/write `User` presentation state.
* Blocks checkout in [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md) — that feature calls this feature's domain interface (`isVerified(userId)`) rather than duplicating verification logic.
* Escalates rejected/retry-exhausted cases to [Admin Dashboard](./11-admin-dashboard.md)'s manual review queue.
* Integrates an external third-party KYC vendor SDK/API (network layer, not a cross-feature import).
* Logged via [Audit Logging](./14-audit-logging.md) for every verification decision.

## 4. Safety, Security & Regulatory Constraints
* Raw ID images must **not** be retained past the vendor's verification result — store only pass/fail, the vendor reference ID, and a derived age. Retention window must be confirmed with legal (see [DPDP Consent, Data Export & Deletion](./16-consent-privacy.md)) before build.
* Verification is mandatory before checkout; browsing remains open to unverified users. This gate must not be relaxed for conversion — it's the platform's core differentiator vs. District/AllEvents.
* Rejection flow: one automated retry only, then routed to human admin review — no unlimited retry loops.
* Every state transition is audit-logged (verification decision) per [Audit Logging](./14-audit-logging.md).
