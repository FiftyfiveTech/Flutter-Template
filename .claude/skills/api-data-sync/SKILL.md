---
name: api-data-sync
description: Use when writing or modifying a remote datasource (Firestore), local datasource (Drift DAO), repository implementation, or DTO/mapper in data/ — networking, offline sync, caching, or backend integration. Triggers on requests like "connect this to Firestore", "add a datasource for X", "wire up offline sync", "cache this content", "call a Cloud Function".
---

# Backend, local storage, and offline-sync conventions

Read `docs/architecture.md` §9 (Networking Architecture), §10 (Local Storage), and §17 (Offline
Strategy) before touching anything in a feature's `data/` layer.

## There is one backend, not two: Cloud Firestore

Per `docs/system_design.md` §13.1/§16, this app has **no custom REST API**. Everything — app/user
data (profiles, daily logs, metrics, streaks) **and** CMS-sourced content (learning modules,
workouts, recipes, meditations) — lives in Firestore, accessed via the `cloud_firestore` SDK.

- The headless CMS pushes to Firestore server-side, via a webhook-triggered Cloud Function
  (`CF_CMS`) — the client never calls the CMS directly, and `dio` is **not** used for this. If you
  find yourself reaching for `dio` or building an `ApiClient` for content or app data, stop — that's
  the wrong track. `dio` is reserved solely for future Phase 2+ Fitbit/Garmin OAuth adapters.
- Media assets (images, diagrams, video) are CDN URLs stored inside Firestore content documents,
  loaded via `cached_network_image` — that package handles its own HTTP fetch/cache internally, no
  custom client needed.
- Auth is automatic: the Firebase Auth ID token is attached by the SDK to every Firestore/Functions
  call — there's no manual bearer-token or refresh-interceptor code to write anywhere in this data
  path.

## Cloud Functions: two kinds, only one of which you ever call

- **Client-invoked (HTTPS Callable)**: `submitOnboardingData`, `generateGpProgressReport`. Call
  these from the repository implementation — never directly from a controller.
- **Event-triggered — you never call these**: `CF_Adaptive` (adaptive-target recalculation) and
  `CF_Metrics` (red-flag evaluation) run automatically server-side when a relevant Firestore
  document is written. The client's job is to write the triggering data (e.g. a metric log) to
  Firestore, then observe the *result* via a Firestore listener once the function has run — never
  try to invoke `CF_Adaptive`/`CF_Metrics` yourselves.
- These Cloud Functions are the **authoritative** computation for adaptive targets and red-flag
  thresholds. The matching Dart domain-layer use case (see `health-safety-compliance` and
  `flutter-feature-scaffold` skills) is a local, offline-capable *preview* of the same rule for
  instant UX — not a replacement for the server result. Don't remove the Cloud Function call
  thinking the local Dart logic is sufficient; don't skip writing the Dart preview logic thinking
  the Cloud Function alone covers it — both need to exist, and a mismatch between the two constants
  is a review-worthy drift risk.

## Repository / sync pattern (§9, §14, §17)

- Repositories combine the Firestore remote datasource with the local Drift datasource, and decide
  sync policy:
  - Content (learning modules, workouts, recipes): read Drift first, refresh from Firestore in
    background (stale-while-revalidate).
  - Logs / user writes: write to Drift immediately (UI updates instantly from the Drift stream),
    then queue the write to `sync_queue` for background push to Firestore; update a `synced` flag
    on success.
- Conflict handling is last-write-wins per record with a server timestamp — a stated assumption in
  architecture.md §17 for single-user use, not built for multi-device concurrency.
- A background sync worker drains `sync_queue` to Firestore on connectivity-restored + periodic
  triggers, processing writes in order. Don't rely on Firestore's own built-in offline queue for
  this — the app's own `sync_queue` is the durable, inspectable record.
- `FirebaseException`s (from either Firestore or Cloud Functions) map to the shared `Failure`
  taxonomy at the data-layer boundary — domain/use cases never see a raw `FirebaseException`.
- Firestore's own offline cache/listener behavior is not relied on for UI reactivity — Drift stays
  the single source of truth the UI streams from; a Firestore listener's only job is to write into
  Drift when remote data changes.

## Local storage (§10)

| Data | Storage |
|---|---|
| Auth/refresh tokens | `flutter_secure_storage` only, never `SharedPreferences` |
| App settings (theme, notification prefs, units) | `SharedPreferences` via a typed wrapper |
| Onboarding/PAR-Q answers, daily logs, metric history, streak state | Drift (synced to Firestore) |
| Cached CMS content | Drift + `cached_network_image` disk cache for media |
| Progress photos | `path_provider` sandbox storage, **never uploaded** |
| Pending sync queue | Drift table `sync_queue` (drained to Firestore) |

## What not to do

- Don't build a `dio`-based `ApiClient` for CMS content or app data — that track doesn't exist in
  Phase 1.
- Don't call a Firestore/Cloud Functions method directly from a repository implementation without
  going through the feature's own remote datasource class.
- Don't call `CF_Adaptive`/`CF_Metrics` from client code — they're event-triggered, not callable.
- Don't make a log/metric write block on Firestore success before updating the UI — local-first
  means Drift is the source of truth the UI reads from, always.
