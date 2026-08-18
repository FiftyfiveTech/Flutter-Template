---
name: flutter-testing
description: Use when writing or reviewing tests for any Dart/Flutter code in this project — unit tests for use cases/mappers, widget tests, repository tests, golden tests, or integration tests. Triggers on requests like "add tests for X", "test this use case", "check test coverage", or as part of finishing a feature per its Definition of Done.
---

# Testing conventions

Read `docs/architecture.md` §18 before writing tests — test type and location depend on the layer
being tested, and this project treats test coverage as part of "done," not an afterthought (§24).

## What to test, per layer

- **Domain (unit tests, the bulk of coverage)**: use cases and mappers. Domain has zero framework
  dependency, so these are pure-function tests — e.g. adaptive-target calculation, minimum-viable-
  day logic, red-flag threshold evaluation (see `docs/features/13-safety-compliance-duty-of-care.md`
  and `docs/features/03-progressive-targets-adaptive-difficulty.md`). These encode PRD safety/
  business rules — test the boundary conditions explicitly, not just the happy path. Remember these
  Dart use cases are a **client-side preview** of rules whose authoritative computation is a Cloud
  Function (`CF_Adaptive`/`CF_Metrics`, see `api-data-sync` skill) — this test suite can't verify
  parity with the TypeScript implementation, only that the Dart preview itself is internally
  correct.
- **Presentation (widget tests)**: feature widgets tested against fake providers via
  `ProviderScope(overrides: [...])`. Verify loading/data/error/empty states all render correctly —
  a widget test that only checks the happy-path data state is incomplete.
- **Data (repository tests)**: repository implementations tested against an in-memory Drift
  database and a fake Firestore instance (`fake_cloud_firestore`), or a `mocktail`-mocked
  callable-function interface for Cloud Function calls (`submitOnboardingData`,
  `generateGpProgressReport`). Verify local-first read/write behavior and that a write correctly
  populates the `sync_queue` table. Event-triggered functions (`CF_Adaptive`, `CF_Metrics`) run in
  a separate TypeScript codebase — out of scope for this Flutter test suite.
- **Integration tests**: key end-to-end flows only (onboarding completion, daily pillar log
  submission, offline log → reconnect → sync) — these are expensive, don't multiply them per
  minor variation.
- **Golden tests**: shared design-system-wrapped widgets in `lib/shared/widgets` (Button, Card,
  ProgressRing, PillarTag) — catches unintended visual regressions when design tokens change.

## Tooling

- `mocktail` for all repository/datasource test doubles — not `mockito`.
- CI runs unit + widget tests on every PR; integration tests run nightly/pre-release given their
  runtime cost — don't add a slow integration test to the per-PR suite.

## Definition of Done gate (§24)

Before a feature is considered done: unit tests for all use cases, widget tests for all UI states,
repository tests for sync/cache behavior, zero lint warnings, and explicit test cases for any PRD
safety/business rule the feature touches. Use `/dod-check` to verify a feature against the full
checklist, not just the testing subset.
