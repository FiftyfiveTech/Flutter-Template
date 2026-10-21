import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// How primary buttons paint their background.
enum AppButtonFill { gradient, solid }

/// Assembles `AppColors`/`AppTypography` into `ThemeData`. `light` is the app's
/// default theme — see `docs/design_systems/tokens/colors.css`'s `.theme-light`
/// block.
abstract final class AppTheme {
  /// Flip to [AppButtonFill.solid] to render every primary button flat.
  static const AppButtonFill buttonFill = AppButtonFill.gradient;

  static ThemeData get light => lightWith(buttonFill);

  /// [light] with an explicit button fill — lets tests exercise both modes.
  static ThemeData lightWith(AppButtonFill fill) {
    final action = switch (fill) {
      AppButtonFill.gradient => AppActionColors.light,
      AppButtonFill.solid => AppActionColors.light.copyWith(
        actionPrimaryFill: LinearGradient(
          colors: [
            AppActionColors.light.actionPrimary,
            AppActionColors.light.actionPrimary,
          ],
        ),
      ),
    };

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      colorScheme: ColorScheme.light(
        primary: action.actionPrimary,
        onPrimary: action.actionPrimaryFg,
        secondary: AppColors.actionSecondary,
        onSecondary: AppColors.actionSecondaryFg,
        error: AppColors.statusError,
        onError: AppColors.textOnAction,
        surface: AppColors.backgroundPrimary,
        onSurface: AppColors.textPrimary,
      ),
      extensions: [
        action,
        AppTypography(
          display: GoogleFonts.bricolageGrotesque(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            height: 1.08,
            letterSpacing: -1.08,
            color: AppColors.textPrimary,
          ),
          h1: GoogleFonts.bricolageGrotesque(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: -0.84,
            color: AppColors.textPrimary,
          ),
          h2: GoogleFonts.bricolageGrotesque(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.42,
            color: AppColors.textPrimary,
          ),
          h3: GoogleFonts.beVietnamPro(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: -0.17,
            color: AppColors.textPrimary,
          ),
          bodyLg: GoogleFonts.beVietnamPro(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
          body: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
          bodySm: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0.065,
            color: AppColors.textPrimary,
          ),
          caption: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.35,
            letterSpacing: 0.12,
            color: AppColors.textSecondary,
          ),
          label: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 1.1,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
