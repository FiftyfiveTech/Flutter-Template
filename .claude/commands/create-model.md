---
description: Scaffold a domain entity + DTO pair with explicit entity/DTO mapping
---

Create a domain entity and its matching DTO for `$ARGUMENTS` (format: `<feature_name> <ModelName>`,
e.g. `sample_counter HistoryEntry`).

1. Read `docs/architecture.md` §3 (Architecture Pattern) and §6 (Networking & API Integration) first.
2. Check the matching feature spec in `docs/features/` for the actual fields this model needs —
   don't invent fields not backed by a spec, ask if the shape is unclear.
3. Create `lib/features/<feature_name>/domain/entities/<model_name>.dart`:
   - Plain immutable Dart class with a `copyWith` — see `counter_record.dart` for the reference
     shape. Zero import from `data/` or `presentation/`, no serialization annotations — domain
     entities don't know about JSON or the DB.
   - If the project later adds `freezed`/`json_serializable` as dependencies, that's a fine upgrade
     to this pattern — but don't add either without flagging it to the user first, since neither is
     a dependency of this template today.
4. Create `lib/features/<feature_name>/data/models/<model_name>_dto.dart`:
   - Mirrors the remote/local shape exactly, with explicit `factory .fromJson`/`toJson` (REST or
     Drift row) or `fromEntity`/`toEntity` mapping — see `counter_dto.dart` for the reference shape.
     No implicit mapping, no DTO instance ever returned from a repository interface.
5. If this model is also persisted locally, add/update the corresponding Drift table definition
   under `data/local/` per §5 (Local Storage & Cache Strategy).
6. Run `dart run build_runner build --delete-conflicting-outputs` if a Drift table changed, then
   `flutter analyze`, and report the result.
