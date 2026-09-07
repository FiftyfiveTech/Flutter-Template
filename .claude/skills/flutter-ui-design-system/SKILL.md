---
name: flutter-ui-design-system
description: Use when building or modifying any widget, page, or visual element in lib/ — presentation/pages, presentation/widgets, or shared/widgets. Triggers on requests like "build the X screen", "add a widget for Y", "style this component", "make this responsive", or any UI work touching color/spacing/type.
---

# Flutter UI against the design system

Never invent a color, spacing, or type value inline in a widget — everything comes from
`lib/core/theme/` (architecture.md §8):

- `lib/core/theme/app_colors.dart` — brand/semantic/neutral color constants.
- `lib/core/theme/app_spacing.dart` — spacing scale, radii, and ready-made `SizedBox` spacers.
- `lib/core/theme/app_typography.dart` — a `ThemeExtension` exposing the type scale, read via
  `Theme.of(context).extension<AppTypography>()!`.
- `lib/core/theme/app_theme.dart` — assembles the above into `ThemeData`.

If a project has a separate design-token source (Figma export, CSS variables, a token JSON from a
design tool), treat that as the source of truth and keep `lib/core/theme/` in sync with it — add
new tokens there first, then reference them from widgets, never hardcode the raw value inline.

## Rules

- **Color tokens** are accessed via `AppColors`, never a raw hex `Color(0x...)` literal in feature
  code.
- **Typography**: read text styles from the `AppTypography` theme extension — don't set a custom
  inline `TextStyle` in a feature widget. If the project has a specific brand font, wire it into
  `AppTheme` once, not per-widget.
- **Spacing**: use `AppSpacing` constants/spacers, no magic-number `EdgeInsets`/`SizedBox` values.
- **Component reuse**: core primitives — buttons, text fields, dropdowns/search fields, cards, and
  any other control that mirrors a component in the project's design system (e.g. a `Button`,
  `TextField`, `SelectField`, `Card` in a `_ds_bundle.js`/Figma kit) — belong in `lib/shared/widgets/`
  from the first screen that needs them, named `Ah<Thing>` (e.g. `AhButton`, `AhTextField`,
  `AhCard`). Build the shared version instead of a one-off styled `ElevatedButton`/`TextField` even
  on the very first usage, so the second and third screens reuse it rather than re-implementing the
  same styling. Only keep a widget feature-local when it's genuinely specific to that feature's flow
  (e.g. a step-progress-dots indicator for one feature's wizard) rather than a general-purpose
  control.
- **Responsive**: mobile-first single column by default; use `LayoutBuilder`/`MediaQuery`
  breakpoints if/when tablet support is added.
- **Dark mode**: this template ships `AppTheme.light` only. If a project needs dark mode, add the
  variant by giving each `ThemeExtension` a second instance and switching on `Brightness` — don't
  bake light-only assumptions (e.g. a fixed white background color used outside the theme) into
  widget code.
- **Accessibility**: minimum tap targets, screen-reader labels (`Semantics`/`tooltip` where
  appropriate), sufficient color contrast, a loading state (never a blank screen) and an empty
  state for every async-backed view — see `CounterPage`'s `AsyncValue.when` for the loading/data/
  error pattern to copy.
- **Localization-ready**: avoid hardcoding user-facing strings so a localization layer can be added
  later without a rewrite, even if only one locale ships initially.
- **Performance**: `const` constructors wherever possible (enforced by lint), scope
  `ref.watch`/`Consumer` narrowly (`.select()`) so one field update doesn't rebuild an entire
  screen, use `autoDispose` for screen-scoped providers.
