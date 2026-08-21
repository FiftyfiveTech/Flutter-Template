---
description: Extract or promote a widget, applying the shared-vs-feature-local boundary rule
---

Refactor/promote the widget `$ARGUMENTS` (a widget name or file path).

1. Read `docs/architecture.md` §3 (Architecture Pattern) before moving anything.
2. Decide where it belongs:
   - Used by exactly one feature → stays in that feature's `presentation/widgets/`.
   - Genuinely used (or about to be used) by a **second** feature → promote to
     `lib/shared/widgets/` (create this folder if it doesn't exist yet). Do not promote
     pre-emptively "in case" a second feature needs it later — that's premature abstraction.
   - App-shell level with no product meaning (error boundary, loading shell, generic empty-state
     scaffold) → `lib/core/widgets/`, not `shared/`.
3. If extracting a widget subtree from a large `build()` method: only extract something reused more
   than once, or something whose size is hurting readability — don't fragment a widget tree into
   many single-use classes for its own sake.
4. When promoting to `shared/`, replace any hardcoded color/spacing/type it contains with the
   proper `AppColors`/`AppTypography`/`AppSpacing` reference (see `flutter-ui-design-system` skill)
   — a promoted widget is a design-system primitive, it shouldn't carry feature-local shortcuts.
5. Update every call site to the new location/import; confirm no feature ends up importing another
   feature's `presentation/widgets` directly as a side effect of the move.
6. Run `flutter analyze` and any existing widget/golden tests for the moved widget, and report the
   result.
