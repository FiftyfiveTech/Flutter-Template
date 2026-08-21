---
description: Scaffold a new feature module under lib/features/ following the Clean Architecture shape in docs/architecture.md
---

Scaffold a new feature module named `$ARGUMENTS` (snake_case) under `lib/features/`.

1. Read `docs/architecture.md` §3 (Architecture Pattern) to confirm the exact required shape before creating anything.
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
3. Do not add example/boilerplate Dart classes unless asked — an empty scaffold matching the shape of the existing `sample_counter` feature is the goal, so the feature can be built out incrementally.
4. Confirm the new feature respects the boundary rule: it must never import another feature's `presentation/` or `data/` internals directly, only `core/`, and other features' `domain/repositories` interfaces.
5. Report the created paths back to the user.
