---
name: pre-commit-review
description: Run before creating a commit or opening a PR — checks a diff against this app's non-negotiable product-safety rules (from docs/features/), Clean Architecture/Riverpod boundaries, and doc-sync requirements that flutter analyze/dart format/flutter test cannot catch. Triggers on "review before commit", "ready to commit?", "pre-commit check", "review this before I commit", or right before actually running `git commit`.
---

# Review checklist — what the build cannot check

Ordered by damage. Everything the toolchain already blocks is deliberately absent — run these
first and only look below at what survives:

```
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

If any of those fail, fix them before doing anything else; don't review a diff that doesn't
compile or format clean.

This skill is the product-specific complement to `/review-code` (structural architecture rules)
and `/dod-check` (full pre-merge checklist) — run those too for a full pass. This file exists for
the part neither one covers: the safety/regulatory rules baked into `docs/features/*.md` that a
generic architecture check has no way to know about.

---

## 1. The product non-negotiables

Any of these in a diff is a **Blocker**, regardless of how reasonable the surrounding code looks.
Source is the cited feature spec's §4 (Safety, Security & Regulatory Constraints) — read it
directly, don't rely on memory of it, specs get amended.

| Rule | What to look for in a diff |
|---|---|
| Draft creation is always permitted; only *publish* is gated on verification (`host-app/01-host-onboarding.md` §4) | A change that blocks draft save/create on `verificationStatus`; publish must be the only thing that checks it |
| Publish is blocked server-side by `isVerified` + `hasValidLicence`, not re-derived (`host-app/01-host-onboarding.md` §3, `host-app/02-host-event-publishing.md` §3–4) | A publish button/controller computing its own "am I verified" logic instead of calling the onboarding feature's domain interface; a local flag standing in for the real check |
| Document/licence set is conditional on `host_type` **and city**, never a flat hardcoded list (`host-app/01-host-onboarding.md` §3–4) | A document checklist that doesn't branch on `hostType`; a city assumption baked into code instead of read from `Platform Foundation` config — "Bangalore-only" is the *current* config, not a permanent constant |
| Excise/FSSAI expiry warnings at 30 and 7 days; publish blocked on lapse (`host-app/01-host-onboarding.md` §4) | An expiry threshold computed inline in a widget instead of a use case; a missing 7-day or 30-day boundary case; a lapsed-licence host whose publish path is still enabled |
| Price/date lock after first sale; capacity may only rise, never below tickets sold (`host-app/02-host-event-publishing.md` §4) | An edit-event form offering to change price/date unconditionally, or a capacity field with no floor at `ticketsSold` — even though the real block is server-side, the client must not offer a control implying it's allowed |
| Ratio band defaults 50:50 ±10; hosts may tighten, never widen past the platform default (`host-app/02-host-event-publishing.md` §4) | A ratio-band input with no clamp against the platform default; a stepper/slider whose range exceeds it |
| First three events route through admin approval (`host-app/02-host-event-publishing.md` §1) | A publish flow that skips submission/approval status regardless of the host's event count |
| `CheckIn` is the sole, unfakeable gate at the door — no manual admin override in MVP (`host-app/03-host-night-operations.md` §4) | Any "mark attended" shortcut that doesn't go through the actual QR/manual-search scan flow |
| QR must be validated as signed **and** single-use before a scan returns valid (`host-app/03-host-night-operations.md` §3–4) | A scanner result path returning "valid" without checking signature/already-used status via the booking feature's domain interface; a second path that can re-validate the same code |
| Female-skew warning is host/ops-facing only — this app may show it, a member surface never may (`host-app/03-host-night-operations.md` §4, `04-booking-ratio-gating.md` §4) | Copy, a string constant, or a widget written here that could leak onto a member-facing surface if promoted to `lib/shared/` later — flag skew-revealing content placed anywhere reachable outside this host app |
| Venue F&B rebate must **not** appear in the payout view (`host-app/03-host-night-operations.md` §4) | A payout widget/entity that includes or computes an F&B rebate figure |
| Every check-in and payout transition is audit-logged (`host-app/03-host-night-operations.md` §3–4, `14-audit-logging.md`) | A check-in or payout state change committed without a corresponding audit-log call, once that shared service exists in this repo |
| Raw ID/selfie/licence document images are never persisted client-side past the upload call (`02-identity-verification.md` §4, applies equally to host onboarding documents) | A picked file/image cached to Drift, `shared_preferences`, or written to a log; a document preview held in memory longer than the upload flow needs |
| Consent is versioned and timestamped — never mutated in place (`16-consent-privacy.md` §4) | A "consent" write that updates an existing record's fields instead of inserting a new version |
| A status shown as confirmed/verified/paid must come from the real async source, never an optimistic local flag (backend analog: no client-side success callback) | A widget that flips to a "confirmed" visual state from local form/controller state instead of `ref.watch`ing the actual repository-backed `AsyncValue` |

If a change appears to *require* softening one of these, that is the finding — say so rather than
reviewing the softened version as if it were fine.

## 2. Clean Architecture & Riverpod boundaries

Condensed from `/review-code` — run that command for the full structural pass; these are the ones
most likely to slip into a "just this once" diff:

- `domain/` imports nothing from `data/`, `presentation/`, `drift`, `dio`, or `cloud_firestore`.
- No feature imports another feature's `presentation/`/`data/` internals — only `core/` and another
  feature's `domain/repositories` interface.
- No business logic (validation, a use-case call, conditional data transformation) inside a
  widget's `build()` — it belongs in the controller.
- A controller never constructs a repository/datasource directly (`Repository()`); always
  `ref.watch(...Provider)`.
- A `Failure` reaching a controller is passed straight through as the error object
  (`AsyncError(failure, ...)`) — never re-wrapped in a generic `Exception`.
- A DTO type never appears in `domain/` or `presentation/` imports.

## 3. Design tokens

- No raw `Color(0x...)`, inline `TextStyle(...)`, or magic-number `EdgeInsets`/`SizedBox` — see
  `flutter-ui-design-system` skill.
- A new button/field/card/dropdown/search control belongs in `lib/shared/widgets/` as `Ah<Thing>`
  from its first use, not duplicated per-feature (see that skill's "Component reuse" rule).

## 4. Docs of record — same commit, not later

- New screen implemented → check off its ID in `docs/features/screen-checklist.md` (`[x]`), or
  mark `[!]` and say why if it exists but doesn't match the spec's "must" clause.
- New business rule, threshold, or config surfaced in code but not in the cited feature spec's §4
  → flag it; that's a spec gap, not something to silently encode only in code.
- New/changed Drift table or column → confirmed against `docs/local_storage.md` if that doc
  describes it; a schema change with no doc update is a gap.
- New third-party package added to `pubspec.yaml` → was it flagged to the user before being added,
  not silently introduced?

## 5. Tests

- Every new/changed `domain/usecases/*` has a corresponding unit test (boundary cases, not just
  happy path — see `flutter-testing` skill).
- Every new/changed screen has a widget test covering loading/data/error states, not just the
  happy path.
- Nothing mocks Riverpod's own state container or Drift directly — fakes/overrides only, per
  `flutter-testing`.

## 6. Review hygiene

- Don't re-flag anything `flutter analyze`/`dart format` already blocks.
- Separate *rule violations* (non-negotiables, Clean Architecture boundaries) from *judgement
  calls* (naming, widget composition) and label which is which.
- Scope creep in the diff (unrelated reformatting, unrelated renames) is itself a finding.
- Report findings first, ordered by severity, with `file:line` — don't apply fixes automatically
  unless asked to.
