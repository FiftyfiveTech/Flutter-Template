---
name: flutter-feature-scaffold
description: Use when generating the actual Dart boilerplate (entities, repository interface, use case, Riverpod controller, DTO, datasource, repository impl) for a feature under lib/features/ in this Flutter project, following the Clean Architecture conventions in docs/architecture.md. Triggers on requests like "scaffold the X feature", "add a use case to Y", "wire up a repository for Z".
---

# Flutter feature scaffold

This project enforces a strict four-layer Clean Architecture shape per feature, described in `docs/architecture.md`. Before generating any file, re-read the relevant section in the architecture document rather than relying on memory.

## Steps

1. Confirm the target feature folder exists under `lib/features/<feature_name>/` with the standard subfolders (see `.claude/commands/new-feature.md` if it doesn't yet).
2. Domain layer first, and it must have zero imports from `data/` or `presentation/`:
   - `domain/entities/<name>.dart` — plain immutable Dart class.
   - `domain/repositories/<name>_repository.dart` — abstract interface only, no implementation.
   - `domain/usecases/<verb_noun>.dart` — single-responsibility class with one public method, doc comment describing the business rule it encodes.
3. Data layer:
   - `data/models/<name>_dto.dart` — DTO mirroring the API/DB shape, with explicit `toEntity()`/`fromEntity()` mapping — never let a DTO leak past `data/`.
   - `data/datasources/` — split remote (Dio/Firestore based remote calls) and local (Drift DAO) data sources.
   - `data/repository_impl/<name>_repository_impl.dart` — implements the domain interface, decides local-first vs remote-first data strategy.
4. Presentation layer:
   - `presentation/controllers/` — Riverpod `AsyncNotifier`/`Notifier` (code-generation flavor) depending only on `domain/usecases`, never on `data/` directly.
   - `presentation/pages/`, `presentation/widgets/` — reuse shared widgets and design-system tokens; never hardcode colors/spacing/type outside theme tokens.
5. Error handling: any failure surfaced from a use case must be a typed `Failure` from `core/error` — never a raw exception reaching a controller.
6. Register any new repository/datasource/controller as a Riverpod provider so it's overridable in tests (`ProviderScope(overrides: [...])`).
7. After generating files, run `flutter analyze` and report any issues — zero-warnings is required.

## What not to do

- Don't add a feature-to-feature import of another feature's `presentation/` or `data/` — only that feature's `domain/repositories` interface, injected via a provider.
- Don't invent a package without flagging it as a new dependency for the user to confirm.
- Don't skip tests — write unit tests for use cases/mappers, widget tests for UI states, and repository tests against mock databases or mock clients.
