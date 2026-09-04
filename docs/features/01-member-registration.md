# Feature Spec: Member Registration & Profile

Phone-OTP signup and the minimum profile a Member needs before browsing events. Source: PRD §4.1.

## 1. User Stories / Jobs-to-be-Done
* As a prospective Member, I want to sign up with just my phone number and an OTP so I don't need a password.
* As a Member, I want to provide a minimal profile (first name, DOB, gender, city, one photo) so I can start browsing quickly.
* As a Member, I want a hard 18+ age gate enforced from my DOB so the platform stays compliant without me having to self-attest.
* As a Member, I want my gender captured once at signup (since the ratio engine depends on it) and changeable only via admin action, not by me casually toggling it.
* As a Member, I want to give explicit, versioned consent (DPDP Act 2023) covering identity verification, photo storage, and post-event first-name/photo sharing with co-attendees, so I understand what I'm agreeing to.
* Acceptance: install → complete unverified profile in under 90 seconds.

## 2. Data Entities & Screens
* **Entity**: `User` (id, phone, firstName, dob, gender, city, photoUrl, verificationStatus, createdAt).
* **Entity**: `ConsentRecord` (userId, version, timestamp, scope) — captured here, owned by [DPDP Consent, Data Export & Deletion](./16-consent-privacy.md).
* **Screens**: Phone Entry (`REG-01`), OTP Confirmation (`REG-02`), Profile Setup (`REG-03`), Consent Capture step (`REG-04`, embedded in signup).

## 3. Dependencies
* Feeds [Identity Verification](./02-identity-verification.md) — verification acts on the `User` created here; this feature only owns `unverified` state, never sets `verified`.
* Depends on [DPDP Consent, Data Export & Deletion](./16-consent-privacy.md)'s domain contract for recording/versioning consent — this feature calls it, does not own consent-retention logic.
* Depends on [Platform Foundation](./17-platform-foundation.md) for OTP/session-token issuance, refresh, and secure device storage.
* Read by [Post-Event Matching](./06-post-event-matching.md) (first name, photo) and [Host Onboarding & Licence Verification](./host-app/01-host-onboarding.md) indirectly (member vs. host account separation) — those features must import this feature's **domain** repository interface only, never its `presentation/` or `data/` internals.

## 4. Safety, Security & Regulatory Constraints
* DPDP Act 2023: consent must be explicit, versioned, and timestamped at signup — no pre-checked boxes.
* Hard age gate at 18+, derived from DOB, non-editable after verification.
* Gender is set once at signup; changing it requires an admin action via [Admin Dashboard](./11-admin-dashboard.md), never a self-service edit.
* Session tokens must use secure device storage with refresh — no long-lived tokens in plain storage.
