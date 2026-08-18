---
description: Scaffold a new route-level page for an existing feature, wired into go_router
---

Create a new route-level page for `$ARGUMENTS` (format: `<feature_name> <PageName>`, e.g.
`daily_logging TodayPage`).

1. Confirm the feature folder exists under `lib/features/<feature_name>/`. If not, run
   `/new-feature` first.
2. Read `docs/architecture.md` §7 (Navigation Architecture) before wiring anything.
3. Create `lib/features/<feature_name>/presentation/pages/<page_name>.dart` — a `ConsumerWidget`
   (or `ConsumerStatefulWidget` only if genuinely needed for local ephemeral state) that reads
   state via `ref.watch` from a controller in `presentation/controllers`, never calling a
   repository or use case directly.
4. Build the page from `lib/shared/widgets` primitives — check the `flutter-ui-design-system`
   skill's rules before writing any raw `Container`/`Text`/color value.
5. Register the route:
   - Add the route constant/builder in the feature's own route file (each feature exposes its own
     route constants — `core/routing` doesn't hardcode feature internals).
   - Wire it into the relevant `ShellRoute` tab or nested navigator in `lib/core/routing` if it's a
     top-level/tab destination; otherwise nest it under the feature's existing route tree.
   - If the page should be reachable via deep link (notification tap, shared report, etc.), add the
     path-based route needed for that per §7.
6. If the page requires onboarding-completion, safety-screening, or subscription gating, confirm
   the top-level `redirect` in `core/routing` already covers it — don't duplicate that guard logic
   inside the page itself.
7. No direct `Navigator.push` calls — navigation intents go through named routes.
8. Run `flutter analyze` and report the result.
