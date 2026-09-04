# Feature Spec: DPDP Consent, Data Export & Deletion

Gap identified in PRD §7: "legal review is listed as a pre-build gate." This feature's decisions block two others (see §3).

## 1. User Stories / Jobs-to-be-Done
* As a Member, I want to give explicit, versioned, timestamped consent at signup covering identity verification, photo storage, and sharing my first name and photo with co-attendees post-event.
* As a Member, I want to request an export of my data.
* As a Member, I want to request deletion of my account and data, and understand what happens to already-shared information (e.g., matches, chat history) when I do.

## 2. Data Entities & Screens
* **Entity**: `ConsentRecord` (userId, version, timestamp, scope), `DataExportRequest`, `DeletionRequest` (userId, requestedAt, status).
* **Screens**: Consent Capture (embedded in [Member Registration & Profile](./01-member-registration.md)'s signup, `REG-04`), Privacy Settings — Export/Delete Request (`PRIV-01`), Admin Fulfillment Queue (`PRIV-02`, part of [Admin Dashboard](./11-admin-dashboard.md)).

## 3. Dependencies
* Consent is captured during [Member Registration & Profile](./01-member-registration.md)'s signup flow — this feature owns the versioning/scope logic; registration calls it.
* **Blocks** [Identity Verification](./02-identity-verification.md)'s raw-ID-image retention window decision until legal confirms it.
* **Blocks** [Chat & Safety Controls](./07-chat-safety.md)'s message retention/deletion behavior decision until legal confirms it.
* Export/deletion requests are fulfilled through [Admin Dashboard](./11-admin-dashboard.md).

## 4. Safety, Security & Regulatory Constraints
* This is an explicit pre-build legal gate per the PRD (§7) — must be resolved before build, not treated as a post-launch cleanup item.
* Consent must be versioned and timestamped; changes to consent scope require a new version, not an in-place mutation of the existing record.
* Deletion requests must account for data shared with third parties in-product (e.g., a co-attendee who already saw a first name/photo via [Post-Event Matching](./06-post-event-matching.md)) — the policy for "already-shared" data must be explicit, not silently ignored.
