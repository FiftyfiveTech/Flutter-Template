---
name: flutter-ui-design-system
description: Use when building or modifying any widget, page, or visual element in lib/ — presentation/pages, presentation/widgets, or shared/widgets. Triggers on requests like "build the X screen", "add a widget for Y", "style this component", "make this responsive", or any UI work touching color/spacing/type.
---

# Flutter UI against the design system

This app has a real design system at `docs/design_systems/` — never invent a color,
spacing, or type value. Read it before writing UI code:

- `docs/design_systems/tokens/*.css` — source-of-truth token values (`colors.css`, `spacing.css`,
  `typography.css`). These map 1:1 to the Dart `ThemeExtension`s
  wired in `lib/core/theme` (architecture.md §8) — if a token isn't in `core/theme` yet, add it
  there mirroring the CSS value, don't hardcode it inline in the widget.
- `docs/design_systems/ui_kits/mobile-app/` — mobile-specific layout reference.
- `docs/design.md` — narrative design system reference.

## Rules (architecture.md §8)

- **Color tokens** (Primary, Secondary, Success, Warning, Danger, Background, Surface) are accessed via the app's `ThemeExtension` or standard `ColorScheme`, never hardcoded hex values.
- **Typography**: Nunito family, weight-driven hierarchy (400/600/700/800) via `TextTheme` — don't
  set custom `TextStyle`s inline in a feature widget.
- **Spacing**: use the shared spacing-scale constants/`EdgeInsets` helpers, no magic numbers.
- **Component reuse**: every design-system primitive is wrapped once in `lib/shared/widgets` and
  reused — never reimplement a primitive per feature. A feature-local widget only gets promoted to
  `shared/` once a second feature genuinely needs it (avoid premature promotion).
- **Responsive**: mobile-first single column is the default; use `LayoutBuilder`/`MediaQuery`
  breakpoints at the shared-widget level so tablet support is additive later.
- **Dark mode**: only light theme ships in Phase 1, but `ThemeData`/`ThemeExtension` should stay
  structured to support a dark variant later without refactoring — don't paint yourself into a
  light-only corner with hardcoded assumptions.
- **Accessibility & DoD (§24)**: minimum tap targets, screen-reader labels (`Semantics`/
  `tooltip`/`excludeSemantics` where appropriate), sufficient color contrast per token values,
  loading states (skeleton/shimmer, never a blank screen) and empty states (never a bare blank
  screen) for every async-backed view.
- **Localization-ready**: no hardcoded user-facing strings outside the localization layer, even
  though only English ships at launch.
- **Performance (§16)**: `const` constructors wherever possible (enforced by lint), scope
  `Consumer`/`ref.watch` narrowly with `.select()` so one metric update doesn't rebuild an entire
  screen, dispose screen-scoped providers with `autoDispose`.
