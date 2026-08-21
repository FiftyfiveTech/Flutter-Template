---
description: Review a diff/file against this project's architecture rules (not the full pre-merge DoD checklist — use /dod-check for that)
---

Review `$ARGUMENTS` (a file, diff, or "the current changes" if omitted) against
`docs/architecture.md`'s structural rules. This is for catching architecture drift *during* work,
not the exhaustive pre-merge checklist — use `/dod-check` for that instead.

Check specifically for:

- **Layer violations** (§3): does `domain/` import anything from `data/` or `presentation/`? Does a
  controller call a repository/datasource directly instead of going through a use case?
- **Feature boundary violations** (§3): does this feature import another feature's `presentation/`
  or `data/` internals, instead of only that feature's `domain/repositories` interface?
- **State management drift** (§4): any business logic sitting inside a widget's `build()`? Any
  `setState`/local state that should be a provider because a second widget now needs it (or vice
  versa — state promoted to a provider that only one widget ever reads)?
- **Hardcoded design values** (§8): raw hex colors, magic-number `EdgeInsets`, or inline
  `TextStyle`s instead of the `lib/core/theme/` tokens.
- **DTO leakage** (§6): a DTO type appearing anywhere in `domain/` or `presentation/`.
- **Error handling** (§7): a raw exception, `FirebaseException`, or unhandled `Future` error
  reaching a controller or widget instead of a typed `Failure`; a `Failure` re-wrapped in a generic
  `Exception` before reaching `AsyncError` instead of being passed through directly.
- **Backend choice consistency** (§6): this template supports both a REST/Dio path and a Firestore
  path per feature — flag a datasource that mixes both SDKs in one class, or a repository calling
  `Dio`/`FirebaseFirestore` directly instead of through the feature's datasource interface.
- **Lint/format**: `flutter analyze` clean, `dart format` applied.

Report findings as a list: file:line, what rule it breaks, and the fix — don't apply fixes
automatically unless asked to.
