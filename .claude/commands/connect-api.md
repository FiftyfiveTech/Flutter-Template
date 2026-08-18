---
description: Wire a feature's remote datasource to Firestore, or to a Cloud Function if server-side logic is needed
---

Connect `$ARGUMENTS` (format: `<feature_name> <what it needs>`, e.g.
`content_libraries "read the workout list"` or `daily_logging "sync logs to Firestore"`) to its
backend.

1. Read `docs/architecture.md` §9 (Networking Architecture) and the matching feature spec's "API
   Requirements" section in `docs/features/`.
2. There is one backend: **Firestore**, via the `cloud_firestore` SDK. This is true for app/user
   data (logs, metrics, profiles) *and* CMS-sourced content (workouts, recipes, learning modules) —
   the CMS syncs into Firestore server-side, the client never calls it directly. Do not reach for
   `dio`/`ApiClient` — that's reserved for a future, unrelated Phase 2+ wearable integration (§9.3).
3. Create/update
   `lib/features/<feature_name>/data/datasources/<feature_name>_firestore_datasource.dart` using
   the `cloud_firestore` SDK directly. Auth context is automatic via the Firebase Auth ID token —
   no manual auth-header logic needed.
4. If server-side logic is required, decide which kind:
   - Needs a value back from the client's own action (e.g. submitting onboarding, generating a PDF
     report) → an **HTTPS Callable Function** (`submitOnboardingData`, `generateGpProgressReport`
     are the existing examples), invoked from the repository implementation.
   - Is a reaction to data the client already wrote to Firestore (adaptive-target recalculation,
     red-flag evaluation) → this is an **event-triggered function** (`CF_Adaptive`, `CF_Metrics`)
     that already runs automatically server-side — don't add a client-side call for it, just make
     sure the repository listens for the resulting Firestore write.
5. Writes go through the local-first pattern — Drift write immediately, Firestore write queued via
   `sync_queue` — never write to Firestore synchronously from a controller-triggered action.
6. Map `FirebaseException`s to the shared `Failure` taxonomy at this boundary.
7. If the data carries health-data payloads, confirm logging redacts it in production (per the
   `health-safety-compliance` skill if PAR-Q/metric data is involved).
8. Report which Firestore collection(s)/Cloud Function(s) were used and any assumption made about
   document shape that should be confirmed against the actual Firestore schema
   (`system_design.md` §14.2 has the originally specified collection schemas — check there first).
