---
description: Scaffold a Riverpod controller/provider for a use case or piece of state
---

Create a Riverpod provider/controller for `$ARGUMENTS` (format: `<feature_name> <ControllerName>`,
e.g. `daily_logging DailyLogFormController`).

1. Read `docs/architecture.md` §6 (State Management Strategy) and §8 (Dependency Injection) first;
   the `riverpod-state-management` skill covers the same ground in more depth.
2. Decide the state category before writing anything: global (`core/`), local/ephemeral (widget
   state, not a provider), or async (`AsyncNotifier`) — don't default to async if the state is
   actually just a local UI toggle.
3. Create `lib/features/<feature_name>/presentation/controllers/<controller_name>.dart` using
   `riverpod_generator` annotations (`@riverpod`), depending only on `domain/usecases` — never
   importing a repository or datasource directly.
4. Errors from a use case are typed `Failure`s — the controller maps them to `AsyncValue.error` (or
   a `Failure`-typed field), never lets a raw exception surface to the widget.
5. Mark screen-scoped controllers `autoDispose`; only add `.keepAlive()` with a stated reason.
6. Confirm the provider is overridable — write (or note the need for) a
   `ProviderScope(overrides: [...])` test setup so this controller is testable against a fake use
   case.
7. Run `dart run build_runner build --delete-conflicting-outputs` for the generated provider code,
   then `flutter analyze`, and report the result.
