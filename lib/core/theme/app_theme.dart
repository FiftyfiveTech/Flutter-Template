import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// How primary buttons paint their background.
enum AppButtonFill { gradient, solid }

/// Assembles `AppColors`/`AppTypography` into `ThemeData`. [light] is the
/// app's default theme and [dark] its counterpart — see the `.theme-light` /
/// `.theme-dark` blocks in `docs/design_systems/tokens/colors.css`. Which one
/// is shown is the host's Appearance choice (`themeModeControllerProvider`).
abstract final class AppTheme {
  /// The default primary-button fill. Switchable at runtime for comparison
  /// via `buttonFillControllerProvider` (the H-12 Profile test toggle).
  static const AppButtonFill buttonFill = AppButtonFill.solid;

  static ThemeData get light => lightWith(buttonFill);

  static ThemeData get dark => darkWith(buttonFill);

  /// [light] with an explicit button fill — lets tests exercise both modes.
  static ThemeData lightWith(AppButtonFill fill) =>
      _build(Brightness.light, AppColors.light, AppActionColors.light, fill);

  /// [dark] with an explicit button fill.
  static ThemeData darkWith(AppButtonFill fill) =>
      _build(Brightness.dark, AppColors.dark, AppActionColors.dark, fill);

  static ThemeData _build(
    Brightness brightness,
    AppColors colors,
    AppActionColors baseAction,
    AppButtonFill fill,
  ) {
    final action = switch (fill) {
      AppButtonFill.gradient => baseAction,
      AppButtonFill.solid => baseAction.copyWith(
        actionPrimaryFill: LinearGradient(
          colors: [baseAction.actionPrimary, baseAction.actionPrimary],
        ),
      ),
    };

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.backgroundPrimary,
      colorScheme:
          (brightness == Brightness.light
                  ? const ColorScheme.light()
                  : const ColorScheme.dark())
              .copyWith(
                primary: action.actionPrimary,
                onPrimary: action.actionPrimaryFg,
                secondary: colors.actionSecondary,
                onSecondary: colors.actionSecondaryFg,
                error: colors.statusError,
                onError: colors.textOnAction,
                surface: colors.backgroundPrimary,
                onSurface: colors.textPrimary,
              ),
      extensions: [
        colors,
        action,
        AppTypography(
          display: GoogleFonts.bricolageGrotesque(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            height: 1.08,
            letterSpacing: -1.08,
            color: colors.textPrimary,
          ),
          h1: GoogleFonts.bricolageGrotesque(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: -0.84,
            color: colors.textPrimary,
          ),
          h2: GoogleFonts.bricolageGrotesque(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.42,
            color: colors.textPrimary,
          ),
          h3: GoogleFonts.beVietnamPro(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: -0.17,
            color: colors.textPrimary,
          ),
          bodyLg: GoogleFonts.beVietnamPro(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: colors.textPrimary,
          ),
          body: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: colors.textPrimary,
          ),
          bodySm: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0.065,
            color: colors.textPrimary,
          ),
          caption: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.35,
            letterSpacing: 0.12,
            color: colors.textSecondary,
          ),
          label: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 1.1,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
