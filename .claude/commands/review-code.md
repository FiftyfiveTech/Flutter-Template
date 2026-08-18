---
description: Review a diff/file against this project's architecture rules (not the full pre-merge DoD checklist — use /dod-check for that)
---

Review `$ARGUMENTS` (a file, diff, or "the current changes" if omitted) against
`docs/architecture.md`'s structural rules. This is for catching architecture drift *during* work,
not the exhaustive pre-merge checklist — use `/dod-check` for that instead.

Check specifically for:

- **Layer violations** (§3, §5): does `domain/` import anything from `data/` or `presentation/`?
  Does a controller call a repository/datasource directly instead of going through a use case?
- **Feature boundary violations** (§13): does this feature import another feature's `presentation/`
  or `data/` internals, instead of only that feature's `domain/repositories` interface?
- **State management drift** (§6): any business logic sitting inside a widget's `build()`? Any
  `setState`/local state that should be a provider because a second widget now needs it (or vice
  versa — state promoted to a provider that only one widget ever reads)?
- **Hardcoded design values** (§12): raw hex colors, magic-number `EdgeInsets`, or inline
  `TextStyle`s instead of the theme tokens.
- **DTO leakage** (§9): a DTO type appearing anywhere in `domain/` or `presentation/`.
- **Error handling** (§11): a raw exception, `FirebaseException`, or unhandled `Future` error
  reaching a controller or widget instead of a typed `Failure`.
- **Wrong backend track** (§9): any `dio`/`ApiClient` usage for CMS content or app data (there is
  no REST layer in Phase 1 — Firestore only; `dio` is reserved for future wearable OAuth adapters),
  or a client-side call to an event-triggered Cloud Function (`CF_Adaptive`, `CF_Metrics`, `CF_CMS`)
  that should instead be observed via a Firestore listener.
- **Safety/business-rule code** (see `health-safety-compliance` skill): if this touches red-flag
  thresholds, PAR-Q screening, or disordered-eating detection, confirm the logic lives in
  `domain/usecases`, not inline in a controller, and has a doc comment stating the rule it encodes.
- **Lint/format**: `flutter analyze` clean, `dart format` applied.

Report findings as a list: file:line, what rule it breaks, and the fix — don't apply fixes
automatically unless asked to.
