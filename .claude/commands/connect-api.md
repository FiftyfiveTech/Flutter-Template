---
description: Wire a feature's remote datasource to REST (Dio) or Firestore
---

Connect `$ARGUMENTS` (format: `<feature_name> <what it needs>`, e.g.
`sample_counter "sync history to a REST endpoint"` or `sample_counter "read live counts from
Firestore"`) to its backend.

1. Read `docs/architecture.md` §6 (Networking & API Integration) and the `api-data-sync` skill
   first.
2. Pick the backend for this feature — this template supports both, side by side, chosen per
   feature:
   - **REST**: use `lib/core/network/base_api_client.dart` (wraps `dio`). Create
     `lib/features/<feature_name>/data/datasources/<feature_name>_rest_datasource.dart`
     implementing the feature's remote datasource interface, calling `BaseApiClient.get/post/put/
     delete`. It throws `NetworkException` on failure.
   - **Firestore**: create
     `lib/features/<feature_name>/data/datasources/<feature_name>_firebase_datasource.dart` using
     the `cloud_firestore` SDK directly. Confirm `Firebase.initializeApp()` is wired in `main.dart`
     (see the comment there) and `flutterfire configure` has been run before relying on this path.
   - See `counter_remote_datasource.dart` for both reference implementations side by side.
3. Bind the chosen implementation in the feature's Riverpod provider (e.g.
   `counterRemoteDatasourceProvider` in `counter_controller.dart`) — this is the only line that
   changes to swap backends; domain/presentation code never changes.
4. Writes go through the repository's chosen sync strategy (Direct Remote / Offline-Only / Outbox
   Sync — see `counter_repository_impl.dart` and the `api-data-sync` skill) rather than calling the
   datasource straight from a controller.
5. Map both `NetworkException` (REST) and `FirebaseException` (Firestore) to the shared `Failure`
   taxonomy at the repository boundary — domain/use cases never see either raw exception type.
6. Report which datasource(s) were added/changed and any assumption made about the request/document
   shape that should be confirmed against the actual backend schema.
