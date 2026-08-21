---
name: flutter-testing
description: Use when writing or reviewing tests for any Dart/Flutter code in this project — unit tests for use cases/mappers, widget tests, repository tests, or golden tests. Triggers on requests like "add tests for X", "test this use case", "check test coverage", or as part of finishing a feature per its Definition of Done.
---

# Testing conventions

Read `docs/architecture.md` §9 (Testing Strategy) before writing tests — test type and doubles
depend on the layer being tested.

## What to test, per layer

- **Domain (unit tests, the bulk of coverage)**: use cases and DTO↔entity mappers. Domain has zero
  framework dependency, so these are pure-function tests — see `test/unit_test.dart` for the
  pattern (a hand-written fake repository, no mocking framework required for a single-method
  interface). If a use case encodes a business rule with a boundary condition (like
  `IncrementCounter`'s "cannot exceed 100"), test the boundary explicitly, not just the happy path.
- **Presentation (widget tests)**: feature widgets tested against fake providers via
  `ProviderScope(overrides: [...])` — see `test/widget_test.dart`, which overrides
  `counterControllerProvider` with a fake `AsyncNotifier`. Verify loading/data/error states all
  render correctly; a widget test that only checks the happy-path data state is incomplete.
- **Data (repository tests)**: repository/datasource implementations tested against an in-memory
  Drift database (`AppDatabase.forTesting(NativeDatabase.memory())`) — see `test/repository_test.dart`.
  For a Firestore-backed datasource, use `fake_cloud_firestore` (not a current dependency — flag it
  before adding). Verify local-first read/write behavior and, for Strategy C features, that a write
  correctly populates `syncQueueEntries`.
- **Golden tests**: add these for any widget promoted to a shared/reusable location, to catch
  unintended visual regressions when design tokens change.

## Tooling

- Plain `flutter_test` is sufficient for this template's simple interfaces (see the hand-written
  fake in `test/unit_test.dart`). If a repository/datasource interface grows complex enough that
  hand-written fakes become unwieldy, `mocktail` is the recommended mocking package — flag it as a
  new dependency before adding it.

## Definition of Done gate

Before a feature is considered done: unit tests for all use cases, widget tests for all UI states,
repository tests for sync/cache behavior, and zero lint warnings. Use `/dod-check` to verify a
feature against the full checklist, not just the testing subset.
