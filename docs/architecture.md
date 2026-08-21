# Architecture Document

*This is a template document. Fill in each section according to your product specifications using Prompt 4 in `ai_workflow.md`.*

---

## 1. Project Overview
Provide a brief summary of the app, its audience, and key product goals.

## 2. Technology Stack
List core frameworks, libraries, database systems, and cloud providers:
* **Frontend**: Flutter (Dart)
* **State Management**: Riverpod (code-generation)
* **Local Storage**: Drift (SQLite)
* **Remote Backend**: [Fill in: REST API / Firebase / Supabase / GraphQL]
* **Navigation**: GoRouter
* **UI styling**: Material Design + Custom Design Tokens (ThemeExtension)

## 3. Architecture Pattern (Clean Architecture)
Describe the folder structure and boundary rules:
* `domain/`: Entities, repository contracts, and use cases (no external package imports).
* `data/`: DTOs, datasource queries, and concrete repositories implementations.
* `presentation/`: Riverpod notifier states, pages, and UI widgets.

## 4. State Management Strategy
Detail state structures:
* Use Riverpod generator (`@riverpod`) to manage and expose states.
* Business logic belongs in Riverpod Notifiers, never inside stateful/stateless widgets.
* Expose states as async when loading data (`AsyncValue`).

## 5. Local Storage & Cache Strategy
* Specify tables in Drift database (`lib/core/database/app_database.dart`).
* Detail caching rules: direct network writes, optimistic updates, or local outbox background synchronization.
* See `docs/local_storage.md` for where the database is initialized, which files own which part
  of it, and what's involved in swapping Drift for a different local storage plugin.

## 6. Networking & API Integration
* **REST APIs**: Configure base URL, timeouts, token interceptors, and error mapping in `lib/core/network/base_api_client.dart`.
* **Firebase**: Define firestore paths and rules in `lib/core/di/` and remote data sources.

## 7. Error Handling
* Intercept raw exceptions (SocketException, DioException, FirebaseException) at the datasource level.
* Map them to typed `Failure` subclasses defined in `lib/core/error/failures.dart`.
* Return a `Result<Failure, SuccessType>` from repositories to use cases and controllers.

## 8. Theme & Design System
* Configure tokens (colors, spacing, typography) in `lib/core/theme/`.
* Declare `ThemeExtension` to expose these tokens safely across all pages without hardcoding color hexes or margins.

## 9. Testing Strategy
* **Unit Tests**: Target use case business rules and DTO mappers.
* **Repository Tests**: Target local database query operations using an in-memory SQLite runner.
* **Widget Tests**: Target presentation state renderings (loading state, loaded state, error state).

## 10. Definition of Done (DoD)
* Code compiles with zero warnings under `flutter analyze`.
* Code formatted using `dart format`.
* Tests build and pass successfully.
* Clean Architecture boundaries are audited and verified.
