# After Hours — Design System (reference)

Direction: **coal & cobalt**. Neutral structure (coal/paper), one accent (cobalt = actionable, teal = verified). No hue on screen means anything else.

## Files in this folder
- `fonts.css` — Bricolage Grotesque (display) + Be Vietnam Pro (body), Google Fonts CDN. Material Symbols Rounded for icons.
- `palette.css` — raw colour ramps (coal, paper, cobalt, teal, sun, rose). Deprecated `--plum-*`/`--amber-*` ramps also live here.
- `colors.css` — semantic tokens (`--color-background-primary`, `--color-text-primary`, `--color-action-primary`, etc.) mapped from the palette, themed light/dark.
- `typography.css` — `--type-*` scale (display/h1/h2/body/label), rem-based.
- `spacing.css` — 4pt grid + 2px hairline step. Gutter 20px, section gap 32, card gap 12.
- `radius.css` — badges 6, buttons 10, inputs/rows 14, cards 16, swipe cards/bubbles 20, sheets 24, chips/avatars full.
- `elevation.css` — `--elevation-1/2` (surface-value based, not shadow-first), `--elevation-focus`.
- `motion.css` — durations 120/200/320/480ms, `--ease-standard` = `cubic-bezier(.2,0,0,1)`.
- `base.css` — resets that consume the above.

## Component library
61 components across 8 groups (`core`, `navigation`, `forms`, `feedback`, `events`, `matching`, `profile`, `chat`), shipped as `AfterHoursDesignSystem_042798` on `window`. Load `_ds_bundle.js` + `styles.css` to use them — see the full bundle at:
`_ds/after-hours-design-system-rj-0427981e-7417-44b7-9bfb-25691a4a4b48/`

## Rules
- Components read semantic tokens only (`--color-*`, `--type-*`, `--spacing-*`, `--radius-*`, `--elevation-*`, `--motion-*`) — never raw palette or hard-coded hex.
- Light: `--cobalt-500` (#2A46E0). Dark: `--cobalt-400` (#5567E6). Both under white text.
- Cards: 16px radius, `--color-surface-card`, near-invisible 7% hairline border, no visible outline.
- Type floor 12px. Touch targets ≥44px, comfortable 48px.
- Sentence case everywhere; no emoji; ₹ tight with number, Indian grouping, tabular figures for prices/counts/countdowns.

Full readme, component `.prompt.md`/`.d.ts` specs, and guideline cards live in the bound design-system project — ask if you need that pulled in too.
