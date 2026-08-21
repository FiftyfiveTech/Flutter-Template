---
name: api-data-sync
description: Use when writing or modifying a remote datasource (REST/Dio or Firestore), local datasource (Drift DAO), repository implementation, or DTO/mapper in data/ — networking, offline sync, caching, or backend integration. Triggers on requests like "connect this to the API", "connect this to Firestore", "add a datasource for X", "wire up offline sync", "cache this content".
---

# Backend, local storage, and offline-sync conventions

Read `docs/architecture.md` §5 (Local Storage), §6 (Networking & API Integration), and §7 (Error
Handling) before touching anything in a feature's `data/` layer.

## Two swappable remote backends, chosen per feature

This template ships both tracks side by side (see `lib/features/sample_counter/data/datasources/`)
and expects most real projects to pick one per feature, not necessarily one for the whole app:

- **REST**: implement against `lib/core/network/base_api_client.dart` (wraps `dio`). It throws a
  `NetworkException` on `DioException`, which the repository maps to a `NetworkFailure`.
- **Firebase/Firestore**: implement against the `cloud_firestore` SDK directly. A `FirebaseException`
  thrown here must be caught and mapped to a `Failure` subclass (typically `ServerFailure`) in the
  repository implementation — see the `on FirebaseException catch (e)` block in
  `counter_repository_impl.dart` for the pattern to copy.
- Which one a feature uses is a single line in that feature's Riverpod provider (e.g.
  `counterRemoteDatasourceProvider`) — domain and presentation code never know which backend is
  active.
- If you add the Firebase path to a new feature, confirm `Firebase.initializeApp()` is wired in
  `main.dart` (see the comment there) and `flutterfire configure` has been run — the Firestore SDK
  throws opaque errors otherwise.

## Repository / sync pattern (§5, §6)

- Repositories combine a local Drift datasource with a remote datasource and decide the sync
  policy per feature. Three strategies are documented inline in `counter_repository_impl.dart`:
  - **Strategy A (Direct Remote, default)**: write to remote first, cache locally on success.
    Simplest, recommended default for standard CRUD.
  - **Strategy B (Offline-Only)**: read/write Drift only, no remote datasource involved.
  - **Strategy C (Outbox Sync, opt-in)**: write to Drift immediately (optimistic UI), enqueue the
    write in `syncQueueEntries`, let `SyncQueueProcessor` (`lib/core/sync/`) drain it in the
    background. Register an adapter with the processor for each entity type using this strategy.
- `FirebaseException`s and `NetworkException`s map to the shared `Failure` taxonomy
  (`lib/core/error/failures.dart`) at the repository boundary — domain/use cases never see a raw
  exception of either kind.
- If you delete the outbox sync components because a project doesn't need them, also remove the
  `SyncQueueProcessor` wiring from `main.dart` and drop `SyncQueueEntries` from `app_database.dart`.

## What not to do

- Don't call a Dio client or the Firestore SDK directly from a repository implementation without
  going through the feature's own datasource class (`CounterRestDatasource`/
  `CounterFirebaseDatasource` are the pattern to copy).
- Don't let a DTO (`data/models/*_dto.dart`) leak into `domain/` or `presentation/` — always map
  through `toEntity()`/`fromEntity()`.
- Don't make a write block the UI on a network/Firestore round-trip if the feature uses the
  local-first outbox strategy — Drift updates the UI immediately, sync happens after.
- Don't invent a new package (e.g. a connectivity or retry library) without flagging it to the user
  first — this template intentionally ships with just `dio` + `cloud_firestore`.
