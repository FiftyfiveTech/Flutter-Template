---
description: Scaffold a new feature module under lib/features/ following the Clean Architecture shape in docs/architecture.md
---

Scaffold a new feature module named `$ARGUMENTS` (snake_case) under `lib/features/`.

1. Read `docs/architecture.md` §4 (Feature-Based Folder Structure) and §5 (Feature Structure) to confirm the exact required shape before creating anything.
2. Create `lib/features/$ARGUMENTS/` with these subfolders, each containing a `.gitkeep` placeholder if left empty:
   - `presentation/pages`
   - `presentation/widgets`
   - `presentation/controllers`
   - `domain/entities`
   - `domain/repositories`
   - `domain/usecases`
   - `data/models`
   - `data/datasources`
   - `data/repository_impl`
3. Do not add example/boilerplate Dart classes unless asked — an empty scaffold matching the existing 14 feature folders is the goal, so a new feature can be built out incrementally.
4. Confirm the new feature respects the boundary rules in §13: it must never import another feature's `presentation/` or `data/` internals directly, only `core/`, `shared/`, `services/`, and other features' `domain/repositories` interfaces.
5. Report the created paths back to the user.
