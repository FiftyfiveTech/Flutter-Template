---
name: flutter-overflow-audit
description: Use when checking Flutter screens/widgets for RenderFlex/layout overflow, especially forms, bottom sheets, and modals where the on-screen keyboard opening shrinks available height. Triggers on requests like "check for overflow", "audit for keyboard overflow", "RenderFlex overflowed", "does this screen handle the keyboard opening".
---

# Overflow & keyboard-safety audit

RenderFlex overflow is a runtime-only failure — `flutter analyze` and unit/widget tests do not
catch it. A static review plus an actual run with the keyboard open are both required before
calling a screen done; neither alone is sufficient.

## Where this breaks, in this codebase's patterns

- Any `TextField`/`TextFormField` screen whose body is a bare `Column` instead of
  `SingleChildScrollView`/`ListView` will overflow vertically the instant the keyboard reduces
  `MediaQuery.viewInsets.bottom` — Flutter doesn't auto-scroll a non-scrollable `Column`.
- `showAppBottomSheet`/`showModalBottomSheet` usages (see
  `lib/shared/widgets/app_bottom_sheet.dart`) need `isScrollControlled: true`, and the sheet's
  content needs `MediaQuery.viewInsets.bottom` added to its bottom padding — a bare `SafeArea` is
  not enough, it doesn't know about the keyboard.
- A fixed footer/Save button placed **inside** the same `Column` as a scrollable form (rather than
  as `Scaffold.bottomNavigationBar`/`persistentFooterButtons`, or inside the scrollable itself) can
  get pushed off-screen or land where a field used to be when the keyboard opens.
- `Scaffold.resizeToAvoidBottomInset` defaults to `true` — don't let it be overridden to `false`
  without a specific reason; that's what lets the body resize/scroll instead of the keyboard
  simply covering content.
- Rows/Columns with several fixed-size children and no `Expanded`/`Flexible` can overflow
  horizontally regardless of keyboard state — a separate, simpler bug class worth checking in the
  same pass (stat rows, pillar chip rows, stepper controls — see
  `lib/features/settings/presentation/widgets/stepper_control.dart`).

## Static pass (do this first, fast)

1. Grep the target file(s), or `lib/features/**/presentation`, for `TextField(` / `TextFormField(`.
2. For each match, walk up the widget tree in the same file and confirm a scrolling ancestor
   (`SingleChildScrollView`, `ListView`, `CustomScrollView`) wraps the field — flag any that don't.
3. For each bottom sheet/modal (`showModalBottomSheet`, `showAppBottomSheet`), confirm
   `isScrollControlled: true` and that `MediaQuery.viewInsets.bottom`/`viewInsetsOf` feeds the
   content's bottom padding.
4. For any footer button rendered alongside a form, confirm it's wired via
   `bottomNavigationBar`/`persistentFooterButtons` (or lives inside the scrollable) rather than as
   a sibling `Column` child below the form.
5. Grep for `Row(` / `Column(` with more than ~3 children and no `Expanded`/`Flexible` inside —
   candidates for overflow independent of the keyboard.

## Dynamic pass (required before sign-off)

Debug builds show overflow as a yellow-and-black striped bar plus a console line
`A RenderFlex overflowed by X pixels on the [bottom/right]` — neither appears in a release build or
in `flutter analyze`, so this must be checked by actually running the screen:

1. Run the app in debug mode (`flutter run`) on the device/emulator, per the `run` skill.
2. Navigate to the screen and tap into every text field on it in turn to raise the keyboard;
   watch the console for `RenderFlex overflowed` and the screen for the striped indicator.
3. For bottom sheets/modals: open them, tap into any field inside, and confirm the sheet
   grows/scrolls above the keyboard rather than clipping or covering the field being edited.
4. If testing on the physical Android test device via adb/uiautomator, re-check the current
   memory notes on that workflow first — keyboard-open layout shifts have caused mis-taps on
   relocated buttons during this exact kind of check before, and stale tap coordinates from
   before the keyboard opened are a common false negative/positive source.

## Reporting

Report findings per screen: file:line of the offending widget, which check it fails (static or
dynamic), and the minimal fix (wrap in scrollable / add `isScrollControlled` / move footer button
out of the scroll column / add `Expanded`). Don't fix automatically unless asked — report first,
matching this project's other review skills (`/review-code`, `/dod-check`).
