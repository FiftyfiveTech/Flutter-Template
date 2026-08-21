---
description: Scaffold a new route-level page for an existing feature, wired into go_router
---

Create a new route-level page for `$ARGUMENTS` (format: `<feature_name> <PageName>`, e.g.
`sample_counter HistoryPage`).

1. Confirm the feature folder exists under `lib/features/<feature_name>/`. If not, run
   `/new-feature` first.
2. Create `lib/features/<feature_name>/presentation/pages/<page_name>.dart` — a `ConsumerWidget`
   (or `ConsumerStatefulWidget` only if genuinely needed for local ephemeral state) that reads
   state via `ref.watch` from a controller in `presentation/controllers`, never calling a
   repository or use case directly. Use `Theme.of(context).extension<AppTypography>()` and
   `AppColors`/`AppSpacing` for all styling — see the `flutter-ui-design-system` skill.
3. Register the route in `lib/core/routing/app_router.dart`:
   ```dart
   GoRoute(
     path: '/your-path',
     name: 'your-route-name',
     builder: (context, state) => const YourPage(),
   ),
   ```
   This template's router is a flat `GoRouter(routes: [...])` list — no nested shells or route
   guards exist yet. If the project grows enough to need auth/onboarding gating or tabbed
   navigation, add that structure deliberately rather than assuming it's already there.
4. No direct `Navigator.push` calls — navigation intents go through named routes.
5. Run `flutter analyze` and report the result.
