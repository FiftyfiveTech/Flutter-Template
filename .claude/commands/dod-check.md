---
description: Review a feature against the Definition of Done checklist in docs/architecture.md §10
---

Review the feature `$ARGUMENTS` (or the current diff/branch if no feature name is given) against the Definition of Done in `docs/architecture.md` §10 before it's merged.

Read §10 directly (do not rely on memory of it) and check each item against the actual code:

- Code compiles with zero warnings under `flutter analyze`
- Code formatted with `dart format`
- Clean Architecture boundaries respected: `domain/` has zero dependency on `data/` or
  `presentation/`; this feature doesn't import another feature's `presentation/`/`data/` internals
- State managed via Riverpod controllers, no business logic in widgets
- No hardcoded colors/spacing/type outside `lib/core/theme/` tokens
- Errors mapped to the shared `Failure` taxonomy and passed through as typed objects, not wrapped
  in a generic `Exception`
- Loading and error states implemented for every async-backed view (not just the happy path)
- Unit tests for use cases/mappers, widget tests covering loading/data/error states, repository
  tests for any local/remote sync behavior — all passing
- Any new dependency was flagged to the user before being added, not silently introduced

Report findings as a checklist: pass/fail per item, with file:line references for anything failing. Do not fix issues automatically — report first, then ask whether to fix.
