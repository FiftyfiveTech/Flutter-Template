---
name: riverpod-state-management
description: Use when writing or modifying any Riverpod provider, controller, or notifier in presentation/controllers, core/di, or services/ — state management, dependency injection, async loading/error state, or provider testing overrides. Triggers on requests like "add a provider for X", "wire up state for Y", "make this async", "override this in a test".
---

# Riverpod state management conventions

This template uses **Riverpod only** (code-generation flavor, `riverpod_generator`/
`riverpod_annotation`) for both state and DI — no `get_it`, no plain `Provider` package, no
`setState`-driven business logic. Read `docs/architecture.md` §4 (State Management) before adding
a provider, and see `lib/features/sample_counter/presentation/controllers/counter_controller.dart`
for the reference shape.

## State categories

- **Global state** (auth session, active user profile, feature flags) — top-level `keepAlive`
  providers in `lib/core/`, read via `ref.watch` anywhere.
- **Local/ephemeral state** (a form field mid-entry, a bottom sheet's open/closed state) — stays in
  `StatefulWidget`/`ConsumerStatefulWidget` local state. Do not promote to a provider unless a
  second widget genuinely needs it.
- **Async state** (fetching data, submitting a write) — model as `AsyncNotifier`/`AsyncValue`,
  giving loading/data/error as one type instead of three booleans. See `CounterController` for the
  pattern: `build()` loads initial state, mutating methods set `AsyncLoading()` then resolve to
  `AsyncData`/`AsyncError`.
- **Multi-step forms**: one notifier holding a draft entity, validated incrementally per step,
  submitted as one payload at the end.

## Dependency injection

- Infrastructure singletons (API client, database, auth/storage wrappers) are `@Riverpod(keepAlive:
  true)` providers in `lib/core/di`, one file per concern — see `network_providers.dart`,
  `database_providers.dart`, `sync_providers.dart`.
- Domain layer depends on abstract repository interfaces; `data/repository_impl` classes bind to
  those interfaces via a provider (e.g. `counterRepositoryProvider` returns the interface type). A
  controller must never construct a repository/datasource directly.
- Providers are lazily instantiated by default — only use `keepAlive()` for something explicitly
  justified (shared infra, a warmed cache), and `autoDispose` for screen-scoped state so memory
  isn't held for flows the user has left.
- Testing: every repository/datasource provider should be swappable via
  `ProviderScope(overrides: [...])` — if a provider can't be overridden cleanly, it's wired wrong.
  See `test/widget_test.dart` for the pattern.

## Failure handling

A controller receives a typed `Failure` (from `core/error`) from a use case/repository and should
pass it straight through as the error object — e.g. `AsyncError(failure, StackTrace.current)` —
never wrap it in a generic `Exception` first. The UI layer reads `failure.message` (or branches on
the concrete `Failure` subtype) to decide what to show; never surface raw exception text. See
`CounterController`/`CounterPage` for the reference implementation.

## What not to do

- Don't put a repository call, a use case invocation with business logic, or any conditional data
  transformation inside a widget's `build()` — that belongs in the controller/notifier.
- Don't watch an entire object where `.select()` on one field would do — avoid unnecessary
  rebuilds of unrelated UI.
