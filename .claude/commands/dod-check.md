---
description: Review a feature against the Definition of Done checklist in docs/architecture.md §24
---

Review the feature `$ARGUMENTS` (or the current diff/branch if no feature name is given) against the Definition of Done in `docs/architecture.md` §24 before it's merged.

Read §24 directly (do not rely on memory of it) and check each item against the actual code:

- Responsive UI matching the bound design system, no hardcoded colors/spacing/type outside tokens
- Uses shared design-system component wrappers (`lib/shared/widgets`), not reimplemented primitives
- State managed via Riverpod controllers per §6, no business logic in widgets
- Repository pattern followed, `domain/` has zero dependency on `data/` or `presentation/`
- Errors mapped to the shared `Failure` taxonomy (§11) and surfaced with warm, non-technical copy
- Loading states implemented for every async operation
- Empty states implemented and copy-reviewed
- Accessibility: minimum tap targets, screen-reader labels, sufficient color contrast
- Localization-ready: no hardcoded user-facing strings outside the localization layer
- Unit tests for all use cases; widget tests for all UI states; repository tests for sync/cache behavior
- Public interfaces documented per §19
- Zero lint warnings (`flutter analyze`)
- Verified against relevant PRD safety/business rules (red-flag thresholds, minimum-viable-day logic, etc.) with explicit test cases

Report findings as a checklist: pass/fail per item, with file:line references for anything failing. Do not fix issues automatically — report first, then ask whether to fix.
