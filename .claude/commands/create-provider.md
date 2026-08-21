---
description: Scaffold a Riverpod controller/provider for a use case or piece of state
---

Create a Riverpod provider/controller for `$ARGUMENTS` (format: `<feature_name> <ControllerName>`,
e.g. `sample_counter HistoryController`).

1. Read `docs/architecture.md` §4 (State Management Strategy) and the `riverpod-state-management`
   skill first.
2. Decide the state category before writing anything: global (`core/di`), local/ephemeral (widget
   state, not a provider), or async (`AsyncNotifier`) — don't default to async if the state is
   actually just a local UI toggle.
3. Create `lib/features/<feature_name>/presentation/controllers/<controller_name>.dart` using
   `riverpod_generator` annotations (`@riverpod`), depending only on `domain/usecases` — never
   importing a repository or datasource directly. See `counter_controller.dart` for the reference
   shape (datasource providers → repository provider → use case provider → `AsyncNotifier`).
4. Errors from a use case are typed `Failure`s — pass them straight through as the `AsyncError`
   object (`AsyncError(failure, StackTrace.current)`), never wrap them in a generic `Exception`
   first.
5. Mark screen-scoped controllers `autoDispose`; only add `.keepAlive()` with a stated reason.
6. Confirm the provider is overridable — write (or note the need for) a
   `ProviderScope(overrides: [...])` test setup so this controller is testable against a fake use
   case, matching `test/widget_test.dart`.
7. Run `dart run build_runner build --delete-conflicting-outputs` for the generated provider code,
   then `flutter analyze`, and report the result.
