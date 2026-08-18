---
description: Scaffold a domain entity + DTO pair with freezed and explicit entity/DTO mapping
---

Create a domain entity and its matching DTO for `$ARGUMENTS` (format: `<feature_name> <ModelName>`,
e.g. `daily_logging DailyLog`).

1. Read `docs/architecture.md` §9 (Networking, DTOs) and §19 (Model rules) first.
2. Check the matching feature spec in `docs/features/` for the actual fields this model needs —
   don't invent fields not backed by a spec, ask if the shape is unclear.
3. Create `lib/features/<feature_name>/domain/entities/<model_name>.dart`:
   - Plain immutable Dart class, `freezed` recommended, zero import from `data/` or `presentation/`.
   - No serialization annotations here — domain entities don't know about JSON or the DB.
4. Create `lib/features/<feature_name>/data/models/<model_name>_dto.dart`:
   - Mirrors the remote shape exactly — CMS DTOs use `json_serializable` for `fromJson`/`toJson`;
     Firestore-backed models use `fromFirestore`/`toFirestore` (a `Map<String, dynamic>` document
     shape) instead, per which track this model belongs to (see `api-data-sync` skill).
   - Explicit `toEntity()` and `fromEntity()` (or `fromDto`) mapping methods/extensions — no
     implicit mapping, no DTO instance ever returned from a repository interface.
5. If this model is also persisted locally, add/update the corresponding Drift table definition
   per §10 — confirm whether it belongs in the encrypted (PAR-Q/health-screening) or standard
   table group before creating it.
6. Run `flutter analyze` (or `dart run build_runner build` if freezed/json_serializable codegen is
   needed) and report the result.
