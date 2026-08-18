---
name: riverpod-state-management
description: Use when writing or modifying any Riverpod provider, controller, or notifier in presentation/controllers, core/di, or services/ — state management, dependency injection, async loading/error state, or provider testing overrides. Triggers on requests like "add a provider for X", "wire up state for Y", "make this async", "override this in a test".
---

# Riverpod state management conventions

This app uses **Riverpod only** (code-generation flavor, `riverpod_generator`/`riverpod_annotation`)
for both state and DI — no `get_it`, no plain `Provider` package, no `setState`-driven business
logic. Read `docs/architecture.md` §6 and §8 before adding a provider.

## State categories (§6)

- **Global state** (auth session, active user profile, onboarding-completion flag, subscription
  entitlement) — top-level providers in `lib/core/`, read via `ref.watch` anywhere.
- **Local/ephemeral state** (a form field mid-entry, a bottom sheet's open/closed state) — stays in
  `StatefulWidget`/`ConsumerStatefulWidget` local state. Do not promote to a provider unless a
  second widget genuinely needs it.
- **Async state** (fetching content, submitting a log, computing an adaptive target) — model as
  `AsyncNotifier`/`AsyncValue`, giving loading/data/error as one type instead of three booleans.
- **Multi-step forms** (onboarding is the canonical example, PRD §6): one notifier holding a draft
  entity, validated incrementally per step, submitted as one payload at the end — see
  `docs/features/01-onboarding-personalisation-engine.md`.

## Dependency injection (§8)

- Infrastructure singletons (Firestore/Cloud Functions instances, Drift database, secure storage wrapper, health-data
  bridge, notification scheduler) are `Provider`s in `lib/core/di`, one file per concern.
- Domain layer depends on abstract repository interfaces; `data/repository_impl` classes bind to
  those interfaces via a provider (e.g. `dailyLogRepositoryProvider` returns the interface type).
  A controller must never construct a repository/datasource directly.
- Providers are lazily instantiated by default — only use `ref.keepAlive()` for something
  explicitly justified (e.g. a warmed CMS content cache), and `autoDispose` for screen-scoped state
  so memory isn't held for flows the user has left.
- Testing: every repository/datasource provider should be swappable via
  `ProviderScope(overrides: [...])` — if a provider can't be overridden cleanly, it's wired wrong.

## Failure handling

A controller receives a typed `Failure` (from `core/error`, see architecture.md §11) from a use
case, never a raw exception or `FirebaseException` — map `Failure` → warm, non-technical copy in
the UI layer, never surface raw error text.

## What not to do

- Don't put a repository call, a use case invocation with business logic, or any conditional data
  transformation inside a widget's `build()` — that belongs in the controller/notifier.
- Don't watch an entire object where `.select()` on one field would do — avoid unnecessary
  rebuilds of unrelated UI (architecture.md §16).
