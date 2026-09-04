# Feature Spec: Analytics Instrumentation

Gap identified in PRD §7: "the 90-day plan is gated on measured funnel, ratio and repeat data. Untracked pilots prove nothing."

## 1. User Stories / Jobs-to-be-Done
* As Product/Ops, I want to measure the signup → verification → booking funnel and the verification-to-checkout drop-off rate.
* As Product/Ops, I want to measure pre-door vs. at-door gender ratio and their delta, across every event.
* As Product/Ops, I want to measure match rate per event, chat-initiation rate on match, and repeat-purchase rate — the four metrics mapped to the PRD's 90-day pilot success gates (§8).
* As Product/Ops, I want host self-serve completion rate (onboarding without ops intervention) tracked.

## 2. Data Entities & Screens
* **Entity**: `AnalyticsEvent` (name, subjectId, eventId, timestamp, properties).
* **Screens**: none end-user-facing; feeds reporting views inside [Admin Dashboard](./11-admin-dashboard.md).

## 3. Dependencies
* Implemented as a shared instrumentation service in `lib/core/analytics/`, called from [Member Registration & Profile](./01-member-registration.md), [Identity Verification](./02-identity-verification.md), [Booking, Ratio Gating & Payments](./04-booking-ratio-gating.md), [Post-Event Matching](./06-post-event-matching.md), [Chat & Safety Controls](./07-chat-safety.md), [Host Onboarding & Licence Verification](./host-app/01-host-onboarding.md) — each feature emits events through this shared interface rather than any feature reading another's raw data.
* Aggregated results are surfaced in [Admin Dashboard](./11-admin-dashboard.md).

## 4. Safety, Security & Regulatory Constraints
* Event payloads must exclude PII beyond IDs already covered under the DPDP consent scope defined in [DPDP Consent, Data Export & Deletion](./16-consent-privacy.md).
* This instrumentation is explicitly required before pilot launch — not optional telemetry — because all four of the PRD's 90-day success gates (§8) depend on it.
