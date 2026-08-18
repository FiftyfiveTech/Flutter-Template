---
description: Run the automated architecture/compliance audit and layer a judgment-tier review on top
---

Audit `$ARGUMENTS` (or the whole repo if no path/feature is given) for the architecture and
compliance issue classes this project has actually shipped before — feature-boundary violations,
hardcoded design values, coarse error handling, cross-feature Drift access, missing use case
tests, and health-data/GDPR gaps.

## 1. Run the mechanical layer first

Run `dart run tool/audit_architecture.dart` and fold its output into the report. It's a pattern-
based scan (no Flutter runtime needed) covering:

1. Cross-feature `presentation/`/`data/` imports (the feature-boundary rule in `CLAUDE.md` and
   `docs/architecture.md` §13).
2. Hardcoded `Color(0x...)` literals outside `lib/core/theme/`, cross-referenced against
   `AppColors` for the token that should have been used instead (§12).
3. Domain use cases with no matching test file under `test/features/*/domain/usecases/`.
4. `catch (_) { ... UnexpectedFailure() }` in `data/repository_impl/*.dart` — swallowing an error
   without preserving whether it was a network/timeout/server failure (§11).
5. Cross-feature raw Drift table access — a datasource/repository reading another feature's table
   directly instead of going through that feature's repository interface.
6. GDPR export completeness — `AppDatabase` tables never referenced by
   `SettingsRepositoryImpl.exportUserData`.
7. `Consent`/`Privacy`-named classes with a `bool` field defaulting to `true`.
8. `debugPrint(...)` calls that dump a raw Firestore `doc.data()`/`.docs.map` payload.

Only take the script's findings at face value for anything with an unambiguous fix (e.g. a color
literal that exactly matches a token); for the rest, use it as a starting point, not a verdict —
false positives are possible on unusual code shapes.

## 2. Judgment-tier checklist (what the script can't pattern-match)

Read `docs/architecture.md` and the relevant `docs/features/*.md` before judging these — don't
rely on memory of section numbers:

- **Promise vs. implementation gaps**: for any client-side safety logic (PAR-Q, red-flag
  thresholds, adaptive-target ceilings, minimum-viable-day rules), does every code path that
  *claims* a safety property in its UI copy or a doc comment actually receive the inputs it needs
  to enforce that property end-to-end? (This is exactly how the PAR-Q "conservative targets"
  promise shipped unwired into `generateInitialTargets` — see the `health-safety-compliance`
  skill.)
- **Logic in the wrong layer**: does any `data/repository_impl/*.dart` contain a private method
  that makes a sequencing/ordering/pass-fail decision (module unlocking, quiz scoring, streak
  grace-period math) that belongs in `domain/usecases` instead, per §3/§5?
- **Client preview vs. server authority**: for adaptive targets and red-flag detection, does the
  code/comments anywhere imply the Dart use case *is* the source of truth, instead of a preview of
  what `CF_Adaptive`/`CF_Metrics` will authoritatively recompute?
- **Consent UX vs. consent default**: even where check 7 finds no `true` default, does the consent
  screen itself pre-select/pre-tick anything, or word a toggle so the "off" state reads as the
  penalized choice?
- **Sync correctness gaps that don't pattern-match**: local write + sync-queue enqueue not wrapped
  in a single Drift transaction; `processPending()` invoked from inside a widget/controller
  `build()`; missing retry/backoff on a queued sync operation.
- **Error taxonomy fidelity**: where check 4 finds a bare `catch (_)`, is the *fix* obvious from
  context (a `FirebaseException.code` that maps cleanly to `NetworkFailure`/`TimeoutFailure`), or
  does it need a human judgment call? Note which.

## 3. Report

Combine both layers into one severity-ordered findings list — most safety/compliance-relevant
first, then structural, then style — each with a one-sentence failure scenario and `file:line`.
Report findings first; do not fix anything automatically unless asked to.
