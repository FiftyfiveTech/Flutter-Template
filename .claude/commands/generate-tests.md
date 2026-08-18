---
description: Generate tests for a given class/file, matching its architectural layer
---

Generate tests for `$ARGUMENTS` (a file path or class name).

1. Read `docs/architecture.md` §18 (Testing Strategy) and the `flutter-testing` skill before
   writing anything — the test type and doubles depend entirely on which layer the target is in.
2. Identify the layer and apply the matching approach:
   - `domain/usecases` or a mapper → unit test, pure Dart, no mocks needed unless the use case
     depends on a repository interface (then use `mocktail` for that interface). Cover boundary
     conditions explicitly if this use case encodes a safety/business rule (see
     `health-safety-compliance` skill) — not just the happy path.
   - `presentation/controllers` or `pages`/`widgets` → widget test with
     `ProviderScope(overrides: [...])` faking the relevant use case/repository providers; assert
     loading, data, error, and empty states all render correctly, not just the data state.
   - `data/repository_impl` → repository test against an in-memory Drift database and a fake
     Firestore instance (`fake_cloud_firestore`), or a `mocktail`-mocked callable-function
     interface for Cloud Function calls; verify local-first read/write behavior and `sync_queue`
     population on writes.
   - `lib/shared/widgets` primitive → golden test in addition to a widget test.
3. Place the test file mirroring the source path under `test/`, matching the existing project
   convention (e.g. `lib/features/x/domain/usecases/foo.dart` →
   `test/features/x/domain/usecases/foo_test.dart`).
4. Run `flutter test <path>` and report pass/fail; if something fails, report the failure rather
   than weakening the assertion to make it pass.
