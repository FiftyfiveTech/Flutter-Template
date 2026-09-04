# Feature Spec: Host Onboarding & Licence Verification

Self-serve host signup with host_type-conditional document verification. Source: PRD §5.1.

## 1. User Stories / Jobs-to-be-Done
* As a prospective Host, I want to sign up with business/organiser name, contact, city, and my `host_type` (club, community, venue, individual operator), which then drives what documents I need to provide.
* As a Club/Community/Individual Host, I want to submit business registration or organiser ID, PAN, and bank/UPI payout details.
* As a Venue Host, I want to submit the above plus premises address proof, FSSAI registration (if serving food), and the applicable state excise licence with validity dates (if serving alcohol).
* As a Host, I want to create draft events while my verification is still pending, so onboarding doesn't stall on review latency — but I can't publish publicly until verified.
* As a Host, I want to be warned before my excise/FSSAI licence expires (30 and 7 days out), and blocked from publishing new events if it lapses.
* Acceptance: self-serve completion without ops intervention (tracked in [Analytics Instrumentation](../15-analytics-instrumentation.md)).

## 2. Data Entities & Screens
* **Entity**: `HostAccount` (id, businessName, contact, city, hostType, verificationStatus), `HostDocument` (hostAccountId, type, fileRef, status), `Licence` (hostAccountId, type: excise/FSSAI, validFrom, validTo, city).
* **Screens**: Host Signup (`HOST-ON-01`), host_type Selection (`HOST-ON-02`), Document Upload (`HOST-ON-03`, conditional per host_type), Verification Status (`HOST-ON-04`).

## 3. Dependencies
* Verification decisions route through [Admin Dashboard](../11-admin-dashboard.md)'s manual review queue.
* Publish-gating consumed by [Host Event Creation & Publishing](./02-host-event-publishing.md) via this feature's domain interface (`isVerified`, `hasValidLicence`) — that feature must not re-derive licence logic itself.
* Payout details validated here feed [Host Night Operations](./03-host-night-operations.md)'s payout view.
* Document/licence set is configurable per city (Bangalore only for pilot) via [Platform Foundation](../17-platform-foundation.md) config, not hardcoded per host_type.

## 4. Safety, Security & Regulatory Constraints
* Document requirements are strictly conditional on `host_type` and city — venues carry a materially heavier document set (address proof, FSSAI, excise licence) than clubs/communities/individual operators.
* Excise and FSSAI licences have enforced expiry dates: a venue Host with a lapsed licence cannot publish new events, and its already-published future events must be flagged to admin. Expiry warnings fire at 30 and 7 days.
* Excise rules are state-level — the required document set must be configurable per city, not hardcoded (Bangalore is the only pilot configuration, but the schema must not assume a single flat document set).
* Bank/UPI payout details must be validated (penny-drop or gateway-side) at onboarding, before any payout can be executed.
* A host cannot publish a public event until verified, though draft creation is always permitted.
