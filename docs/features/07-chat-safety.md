# Feature Spec: Chat & Safety Controls

Realtime text chat on mutual match, plus block/report/unmatch. Source: PRD §4.6 and the §7 gap "Report / block / safety escalation."

## 1. User Stories / Jobs-to-be-Done
* As a matched Member, I want realtime text-only chat with a match list and unread indicators.
* As a matched Member, I want the chat to open on mutual match and stay open for 72 hours from match creation, with a visible countdown from the moment the thread opens — I should never discover the expiry by losing a conversation.
* As a matched Member, I want warning pushes at 12 hours and 1 hour remaining.
* As a Member, once a thread expires I want to still read the transcript but not be able to send — expiry should not feel like data loss.
* As a Member, I want to block (silently to the other party), report, or unmatch from within a chat thread.
* Acceptance: message delivery under 1s at p95; block takes effect immediately and irreversibly for that pair.

## 2. Data Entities & Screens
* **Entity**: `ChatThread` (matchId, openedAt, expiresAt, status), `Message`, `BlockRecord` (blockerId, blockedId, createdAt), `Report` (reporterId, reportedId, threadId, reason, createdAt).
* **Screens**: Chat Thread (`CHAT-01`), Match List w/ Unread Indicators (`CHAT-02`), Block/Report/Unmatch Confirmation Sheets (`CHAT-03`).

## 3. Dependencies
* Thread creation is triggered by a `Match` from [Post-Event Matching](./06-post-event-matching.md) — consumes that feature's domain interface only.
* New-message and expiry-warning pushes are dispatched via [Notifications](./13-notifications.md).
* Reports escalate into [Admin Dashboard](./11-admin-dashboard.md)'s incident queue.
* A block removes both users from each other's future event pools — implemented by calling [Post-Event Matching](./06-post-event-matching.md)'s domain interface (mutual-exclusion rule), not by this feature reaching into that feature's data layer.
* Realtime transport relies on [Platform Foundation](./17-platform-foundation.md)'s websocket infrastructure.
* Retention/deletion behavior for messages is governed by [DPDP Consent, Data Export & Deletion](./16-consent-privacy.md) and must be resolved before build.

## 4. Safety, Security & Regulatory Constraints
* Block is silent to the blocked party and irreversible for that pair; it must also remove both users from each other's future event pools ([Post-Event Matching](./06-post-event-matching.md)).
* At expiry, the thread must remain readable but sending must be disabled — never delete the transcript outright (avoids the perception of data loss).
* Message retention and deletion behavior must be explicitly defined against DPDP before build ([DPDP Consent, Data Export & Deletion](./16-consent-privacy.md) is the blocking dependency).
* Report routes to human admin escalation in MVP; a "discreet in-app help signal" is explicitly deferred to fast-follow, not MVP scope.
* The paid chat-extension-beyond-72-hours tier is out of MVP scope regardless of how it's specced later — do not build hooks for it now.
