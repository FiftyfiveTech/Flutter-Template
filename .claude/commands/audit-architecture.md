---
description: Run a repo-wide architecture/compliance audit against this template's Clean Architecture rules
---

Audit `$ARGUMENTS` (or the whole repo if no path/feature is given) against
`docs/architecture.md` and `CLAUDE.md`'s structural rules. Unlike `/review-code` (scoped to a
diff/file), this checks the whole codebase for drift that accumulates over time.

There is no standalone audit script in this template (`grep`/`Grep` searches below are sufficient
for its current size) — if the project grows large enough to want an automated scan, that's a
reasonable thing to build, but don't assume one exists.

## Checks to run

1. **Cross-feature boundary violations** (§3): grep every `lib/features/*/presentation` and
   `lib/features/*/data` import line for another feature's `presentation/` or `data/` path. Only
   `core/` and other features' `domain/repositories` interfaces are allowed across a feature
   boundary.
2. **Domain purity** (§3): grep `lib/features/*/domain/` for any import of `package:drift`,
   `package:dio`, `package:cloud_firestore`, or a `../data/`/`../presentation/` relative import —
   domain must have zero dependency on either.
3. **Hardcoded design values** (§8): grep `lib/features/**/presentation` for raw `Color(0x`,
   inline `TextStyle(`, or numeric `EdgeInsets`/`SizedBox` literals instead of `AppColors`/
   `AppTypography`/`AppSpacing`.
4. **Coarse error handling** (§7): grep `data/repository_impl/*.dart` for a bare
   `catch (_) { ... UnexpectedFailure() }` sitting alongside an unhandled specific exception type
   (e.g. `FirebaseException` not caught in a repository that uses a Firestore datasource) —
   swallowing a specific, mappable error into a generic one loses diagnostic information.
5. **DTO leakage** (§6): grep `domain/` and `presentation/` for any `*Dto` type reference — a DTO
   should never cross out of `data/`.
6. **Riverpod provider construction** (§4): grep controllers for `new` or direct instantiation of a
   repository/datasource class instead of `ref.watch(...Provider)`.
7. **Missing use case tests**: for each file in `domain/usecases/`, confirm a corresponding test
   exists under `test/` (see `flutter-testing` skill for this template's current flat test-file
   convention).
8. **Dead/unused core modules**: e.g. `SyncQueueProcessor`/`syncQueueEntries` present but never
   invoked from anywhere (`main.dart` or a repository) — if a project isn't using the outbox
   strategy, either wire it up or delete it per the README's "fully modular, delete if unused" note.

## Report

Combine findings into one severity-ordered list — structural boundary violations first, then error
handling/testing gaps, then style — each with a one-sentence failure scenario and `file:line`.
Report findings first; do not fix anything automatically unless asked to.
