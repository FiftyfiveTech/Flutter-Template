---
description: Generate tests for a given class/file, matching its architectural layer
---

Generate tests for `$ARGUMENTS` (a file path or class name).

1. Read `docs/architecture.md` §9 (Testing Strategy) and the `flutter-testing` skill before writing
   anything — the test type and doubles depend entirely on which layer the target is in.
2. Identify the layer and apply the matching approach:
   - `domain/usecases` or a mapper → unit test, pure Dart. A hand-written fake of the repository
     interface is enough for a small interface (see `test/unit_test.dart`); reach for `mocktail`
     only once a fake becomes unwieldy, and flag it as a new dependency first if not already added.
     Cover boundary conditions explicitly if the use case encodes a business rule — not just the
     happy path.
   - `presentation/controllers` or `pages`/`widgets` → widget test with
     `ProviderScope(overrides: [...])` faking the relevant controller/use case/repository provider
     (see `test/widget_test.dart`); assert loading, data, and error states all render correctly,
     not just the data state.
   - `data/repository_impl` or a Drift datasource → repository test against an in-memory Drift
     database (`AppDatabase.forTesting(NativeDatabase.memory())`, see `test/repository_test.dart`).
     For a Firestore-backed datasource, `fake_cloud_firestore` is the recommended package — flag it
     as a new dependency before adding, since it isn't in `pubspec.yaml` yet.
3. Place the test file under `test/`. This template currently uses flat files
   (`test/unit_test.dart`, `test/widget_test.dart`, `test/repository_test.dart`) since it has one
   sample feature — once a project has multiple features, switch to mirroring the source path
   (e.g. `lib/features/x/domain/usecases/foo.dart` → `test/features/x/domain/usecases/foo_test.dart`)
   so the flat files don't become unmanageable.
4. Run `flutter test <path>` and report pass/fail; if something fails, report the failure rather
   than weakening the assertion to make it pass.
