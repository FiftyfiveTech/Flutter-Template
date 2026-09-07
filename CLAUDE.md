# Clean Architecture Starter Template

This template is configured with a strict, four-layer Clean Architecture structure per feature, managed via Riverpod and Drift (SQLite).

## Source of Truth
Before making design decisions or modifying code structure, read:
- `docs/architecture.md` — The technical blueprint (state management, error handling, tests).
- `docs/ai_workflow.md` — Step-by-step AI workflow guidelines.
- `docs/design_systems/tokens/` — CSS design tokens.

## Structural Boundaries
Every feature resides in `lib/features/<feature_name>/` and is divided into three main layers:
1. **Domain Layer (`domain/`)**: Holds entities, repository contracts (interfaces), and single-responsibility use cases. It must have **zero dependencies** on external frameworks, local databases, or network libraries.
2. **Data Layer (`data/`)**: Implements repository interfaces, defines Data Transfer Objects (DTOs), and handles raw queries to local/remote datasources.
3. **Presentation Layer (`presentation/`)**: Contains UI screens (pages), widgets, and Riverpod controllers (notifiers). Controllers depend *only* on use cases, never directly on datasources.

### Cross-Feature Boundary Rule:
A feature must **never** import the `presentation/` or `data/` internals of another feature. It may only import:
* Core shared code (`lib/core/` and `lib/shared/`).
* The **domain repositories interface** of another feature, injected via a Riverpod provider.

---

## Technical Stack Guidelines

### 1. State Management (Riverpod)
* Use the **code-generation** flavor of Riverpod (`@riverpod` and `@Riverpod(keepAlive: true)`).
* Keep business logic entirely outside UI widgets. Widgets should only listen to providers.

### 2. Swap-Friendly Backend Design
* **REST APIs**: Utilize `lib/core/network/base_api_client.dart` (which wraps `dio`) for standard GET, POST, PUT, DELETE requests.
* **Firebase**: Implement your remote datasources using the `cloud_firestore` SDK.
* To switch from REST to Firebase, modify the Riverpod provider in your feature's data layer (e.g. `counterRemoteDatasourceProvider`) to return the Firestore implementation instead of the REST client implementation. No domain code changes are required.

### 3. Modular Sync Strategies
* **Strategy A (Direct Remote)**: Writes directly to the server, waiting for response. Local storage is only updated after a successful write. Recommended default.
* **Strategy B (Offline-Only)**: Reads and writes directly to local Drift database. Remote sync is omitted.
* **Strategy C (Opt-In Outbox Sync)**: Writes locally instantly (optimistic UI), enqueues write task in the outbox table, and triggers background sync. Plug-in elements are in `lib/core/sync/`.

---

## Coding & Format Rules
* **No hardcoded values**: Spacing, colors, and typography must be read from the app's `ThemeExtension` (configured under `lib/core/theme/`).
* **Typed Failures**: Errors returned from use cases to controllers must be mapping into typed subclasses of `Failure` (from `lib/core/error/failures.dart`).
* **Zero Warnings**: Ensure `flutter analyze` passes with 0 warnings before commits.
* **Code Formatting**: Run `dart format .` to format all code.
* **Before every commit**: run the `pre-commit-review` skill (`.claude/skills/pre-commit-review/SKILL.md`) — it checks a diff against this app's non-negotiable product-safety rules (ratio asymmetry, verification/publish gating, QR single-use, check-in as sole matching gate, no raw ID retention, audit-log coverage) that `flutter analyze`/tests can't catch.

## Available Tooling commands
If using an AI coding assistant (like Antigravity / Claude Code):
* `/new-feature <name>` — Scaffolds folders and `.gitkeep` files for a new Clean Architecture feature.
* `/create-screen <name>` — Generates a screen page using theme tokens.
* `/create-provider <name>` — Scaffolds a Riverpod controller/notifier.
* `/create-model <name>` — Scaffolds an immutable data model.
* `/dod-check` — Performs Definition of Done audit.
