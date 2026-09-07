---
name: performance-audit
description: Use when checking Flutter screens/widgets/providers for jank, dropped frames, excessive rebuilds, or memory bloat — const-constructor discipline, rebuild-tree scoping, list/image decode cost, disposal leaks. Triggers on requests like "check for performance issues", "why is this screen janky", "audit for jank/lag", "is this rebuilding too much".
---

# Performance audit

Most jank in a Riverpod + Flutter app comes from one of four sources: widgets rebuilding wider
than they need to, images decoded at far higher resolution than they're displayed at, unbounded
lists built eagerly instead of lazily, and resources (controllers, streams, subscriptions) never
disposed. `flutter analyze` catches some of this via lint (`prefer_const_constructors`,
`cancel_subscriptions`, `close_sinks`, `use_key_in_widget_constructors` — see
`analysis_options.yaml`), but the rebuild-scope and decode-cost classes below are invisible to
static analysis and need a deliberate read plus a profiled run.

## Common failure patterns

- **`ref.watch(someProvider)` on a whole object where only one field is read** — any change to any
  field of that provider's state rebuilds the whole subtree. Prefer
  `ref.watch(someProvider.select((s) => s.field))` when a widget only needs one field (see
  `riverpod-state-management` skill for provider scoping conventions).
- **`ConsumerWidget`/`Consumer` wrapping more UI than actually depends on the watched provider** —
  push the `Consumer` down to the smallest subtree that needs the rebuild, leave static siblings
  outside it.
- **Missing `const`** on widget subtrees that never change between rebuilds — the const lints catch
  the constructor-call case, but not e.g. a `const` that got dropped after a refactor added a
  non-const default argument, or a helper method that returns `Widget` (non-const by construction)
  where a `const` field/getter would do.
- **Full-resolution images decoded for a small display box** — `Image.asset`/`Image.network`
  without `cacheWidth`/`cacheHeight` decodes the source at its native resolution before downscaling
  for display, burning decode time and image-cache memory proportional to the *source* size, not
  the rendered size. Any bundled asset noticeably larger than its largest on-screen box (check with
  the JPEG/PNG's actual pixel dimensions, not file size — a small file can still be many
  megapixels) needs `cacheWidth`/`cacheHeight` sized to `renderSize * MediaQuery.devicePixelRatio`.
- **`Column`/`ListView(children: [...])` for a list whose length depends on data** — builds every
  item eagerly regardless of what's visible. Use `ListView.builder`/`.separated` (or
  `SliverList.builder` in a `CustomScrollView`) for anything backed by a collection that can grow,
  even if it happens to be short today.
- **Undisposed controllers in `StatefulWidget`** — `AnimationController`, `TextEditingController`,
  `ScrollController`, `PageController`, stream subscriptions: each needs `.dispose()`/`.cancel()`
  in `dispose()`. The `cancel_subscriptions`/`close_sinks` lints catch some of this but not
  controller classes without a `Sink`/`StreamSubscription` type.
- **`autoDispose` missing on screen-scoped providers** — a provider that holds state only relevant
  while one screen is visible should be `autoDispose` (per `riverpod-state-management`); without
  it, state and any resources it holds outlive the screen.
- **Expensive work inside `build()`** — parsing, sorting, filtering, or `DateTime.now()`-based
  formatting recomputed on every rebuild instead of memoized in the controller/notifier or hoisted
  to a field computed once.
- **`Opacity` used for a static (non-animating) partial-transparency effect** — forces a full
  offscreen composite every frame; use a pre-blended color (`Color.withValues(alpha:)` on the
  paint, not the widget) or `AnimatedOpacity`/`FadeTransition` only when actually animating.

## Static pass (do this first, fast)

1. Grep the target file(s) for `ref.watch(` — for each, check whether the watched provider exposes
   more fields than the widget reads; flag missing `.select()`.
2. Grep for `Image.asset(` / `Image.network(` / `Image.file(` — for each, confirm `cacheWidth`/
   `cacheHeight` (or an equivalent pre-sized `ResizeImage`) is present, and cross-check the source
   asset's actual pixel dimensions (not file size) against its largest on-screen box.
3. Grep for `Column(` / `Row(` whose `children:` list is built from `.map(...).toList()` over a
   collection, or any `ListView(children: [...])` — these should usually be `.builder`/
   `.separated` instead.
4. Grep for `StatefulWidget` subclasses with `Controller`/`Subscription` fields — confirm a
   matching `dispose()`/`cancel()` call exists.
5. Grep provider definitions (`@riverpod`/`@Riverpod`) used only from a single screen's
   `presentation/` — confirm `autoDispose` (the default; flag any `keepAlive: true` that isn't
   justified as shared infra).
6. Skim `build()` methods for inline sorting/filtering/formatting that doesn't depend on widget
   params changing — candidates to hoist into the controller or a memoized field.

## Dynamic pass (required before sign-off on a suspected-janky screen)

Static review catches shape; only a profiled run shows whether frames actually drop:

1. Run `flutter run --profile` (never judge jank from a debug build — debug mode's overhead
   dwarfs real jank) on a physical device.
2. Open DevTools' Performance view, enable "Track widget rebuilds," and interact with the flagged
   screen (scroll, navigate, trigger the state change under suspicion).
3. Look for frames over the 16ms (60fps) / 8ms (120fps) budget in the timeline, and for widgets
   rebuilding far more often than the interaction should cause.
4. For an image-heavy screen, check DevTools' Memory view for image cache size before/after
   `cacheWidth`/`cacheHeight` fixes — this is the most direct before/after signal for that class of
   fix.

## Reporting

Report findings per file:line, which check it fails (static rule or a specific dynamic-pass
observation), and the minimal fix (add `.select()`, add `cacheWidth`/`cacheHeight`, switch to
`.builder`, add `dispose()`, add `autoDispose`). Don't fix automatically unless asked — report
first, matching this project's other audit skills (`flutter-overflow-audit`, `/review-code`,
`/dod-check`).
