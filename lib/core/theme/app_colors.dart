import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Semantic color tokens, exposed through `ThemeData.extensions` so every
/// widget follows the active theme — read them with `context.colors`.
///
/// [light] mirrors the `.theme-light` block and [dark] the `.theme-dark`
/// block in `docs/design_systems/tokens/colors.css` (the shared paper/coal/
/// ink/teal/sun/rose system). Action tokens instead carry the Host app's own
/// dusty-rose brand accent (replacing the shared system's cobalt). Raw values
/// live in [AppPalette]; this file only maps them to meaning.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surfaceCard,
    required this.surfaceRaised,
    required this.scrim,
    required this.borderDefault,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAction,
    required this.actionPrimary,
    required this.actionPrimaryHover,
    required this.actionPrimaryPressed,
    required this.actionPrimaryFg,
    required this.actionSecondary,
    required this.actionSecondaryFg,
    required this.actionTertiaryFg,
    required this.actionDestructive,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
    required this.statusInfo,
    required this.trustVerified,
  });

  static const light = AppColors(
    backgroundPrimary: AppPalette.paper100,
    backgroundSecondary: AppPalette.paper200,
    surfaceCard: AppPalette.paper050,
    surfaceRaised: AppPalette.white,
    scrim: AppPalette.blackAlpha55,
    borderDefault: AppPalette.ink900Alpha07,
    borderStrong: AppPalette.ink900Alpha16,
    textPrimary: AppPalette.ink900,
    textSecondary: AppPalette.ink500,
    textTertiary: AppPalette.ink400,
    textOnAction: AppPalette.white,
    actionPrimary: AppPalette.primary400,
    actionPrimaryHover: AppPalette.primary300,
    actionPrimaryPressed: AppPalette.primary500,
    actionPrimaryFg: AppPalette.white,
    actionSecondary: AppPalette.paper200,
    actionSecondaryFg: AppPalette.ink900,
    actionTertiaryFg: AppPalette.primary500,
    actionDestructive: AppPalette.rose500,
    statusSuccess: AppPalette.teal600,
    statusWarning: AppPalette.sun600,
    statusError: AppPalette.rose500,
    statusInfo: AppPalette.primary400,
    trustVerified: AppPalette.teal600,
  );

  static const dark = AppColors(
    backgroundPrimary: AppPalette.coal900,
    backgroundSecondary: AppPalette.coal950,
    surfaceCard: AppPalette.coal800,
    surfaceRaised: AppPalette.coal700,
    scrim: AppPalette.coalScrim,
    borderDefault: AppPalette.whiteAlpha07,
    borderStrong: AppPalette.whiteAlpha16,
    textPrimary: AppPalette.coalText,
    textSecondary: AppPalette.coal300,
    textTertiary: AppPalette.coal400,
    textOnAction: AppPalette.white,
    actionPrimary: AppPalette.primary300,
    actionPrimaryHover: AppPalette.primary200,
    actionPrimaryPressed: AppPalette.primary400,
    actionPrimaryFg: AppPalette.white,
    actionSecondary: AppPalette.coal700,
    actionSecondaryFg: AppPalette.coalText,
    actionTertiaryFg: AppPalette.primary200,
    actionDestructive: AppPalette.rose300,
    statusSuccess: AppPalette.teal300,
    statusWarning: AppPalette.sun300,
    statusError: AppPalette.rose300,
    statusInfo: AppPalette.primary200,
    trustVerified: AppPalette.teal300,
  );

  // Background
  final Color backgroundPrimary;
  final Color backgroundSecondary;

  // Surface
  final Color surfaceCard;
  final Color surfaceRaised;
  final Color scrim;

  // Border
  final Color borderDefault;
  final Color borderStrong;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnAction;

  // Action — Host brand accent (dusty rose), not the shared system's cobalt.
  final Color actionPrimary;
  final Color actionPrimaryHover;
  final Color actionPrimaryPressed;
  final Color actionPrimaryFg;
  final Color actionSecondary;
  final Color actionSecondaryFg;
  final Color actionTertiaryFg;
  final Color actionDestructive;

  // Status
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;
  final Color statusInfo;

  // Trust
  final Color trustVerified;

  @override
  AppColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? surfaceCard,
    Color? surfaceRaised,
    Color? scrim,
    Color? borderDefault,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnAction,
    Color? actionPrimary,
    Color? actionPrimaryHover,
    Color? actionPrimaryPressed,
    Color? actionPrimaryFg,
    Color? actionSecondary,
    Color? actionSecondaryFg,
    Color? actionTertiaryFg,
    Color? actionDestructive,
    Color? statusSuccess,
    Color? statusWarning,
    Color? statusError,
    Color? statusInfo,
    Color? trustVerified,
  }) {
    return AppColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      scrim: scrim ?? this.scrim,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnAction: textOnAction ?? this.textOnAction,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryHover: actionPrimaryHover ?? this.actionPrimaryHover,
      actionPrimaryPressed: actionPrimaryPressed ?? this.actionPrimaryPressed,
      actionPrimaryFg: actionPrimaryFg ?? this.actionPrimaryFg,
      actionSecondary: actionSecondary ?? this.actionSecondary,
      actionSecondaryFg: actionSecondaryFg ?? this.actionSecondaryFg,
      actionTertiaryFg: actionTertiaryFg ?? this.actionTertiaryFg,
      actionDestructive: actionDestructive ?? this.actionDestructive,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusError: statusError ?? this.statusError,
      statusInfo: statusInfo ?? this.statusInfo,
      trustVerified: trustVerified ?? this.trustVerified,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      backgroundPrimary: mix(backgroundPrimary, other.backgroundPrimary),
      backgroundSecondary: mix(backgroundSecondary, other.backgroundSecondary),
      surfaceCard: mix(surfaceCard, other.surfaceCard),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      scrim: mix(scrim, other.scrim),
      borderDefault: mix(borderDefault, other.borderDefault),
      borderStrong: mix(borderStrong, other.borderStrong),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      textOnAction: mix(textOnAction, other.textOnAction),
      actionPrimary: mix(actionPrimary, other.actionPrimary),
      actionPrimaryHover: mix(actionPrimaryHover, other.actionPrimaryHover),
      actionPrimaryPressed: mix(
        actionPrimaryPressed,
        other.actionPrimaryPressed,
      ),
      actionPrimaryFg: mix(actionPrimaryFg, other.actionPrimaryFg),
      actionSecondary: mix(actionSecondary, other.actionSecondary),
      actionSecondaryFg: mix(actionSecondaryFg, other.actionSecondaryFg),
      actionTertiaryFg: mix(actionTertiaryFg, other.actionTertiaryFg),
      actionDestructive: mix(actionDestructive, other.actionDestructive),
      statusSuccess: mix(statusSuccess, other.statusSuccess),
      statusWarning: mix(statusWarning, other.statusWarning),
      statusError: mix(statusError, other.statusError),
      statusInfo: mix(statusInfo, other.statusInfo),
      trustVerified: mix(trustVerified, other.trustVerified),
    );
  }
}

/// `context.colors.textPrimary` — the active theme's [AppColors].
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Primary-action tokens exposed through `ThemeData.extensions`, so the
/// primary button fill can be swapped (gradient vs solid, see
/// `buttonFillControllerProvider`) without widgets branching on the mode.
@immutable
class AppActionColors extends ThemeExtension<AppActionColors> {
  const AppActionColors({
    required this.actionPrimary,
    required this.actionPrimaryFg,
    required this.actionPrimaryFill,
  });

  static const _actionPrimaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .5, 1],
    colors: [
      AppPalette.primaryGradientTop,
      AppPalette.primaryGradientMid,
      AppPalette.primaryGradientBottom,
    ],
  );

  /// One step lighter than [_actionPrimaryGradient] so the fill keeps its
  /// contrast against coal surfaces.
  static const _actionPrimaryGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .5, 1],
    colors: [
      AppPalette.primary200,
      AppPalette.primary300,
      AppPalette.primary400,
    ],
  );

  static final light = AppActionColors(
    actionPrimary: AppColors.light.actionPrimary,
    actionPrimaryFg: AppColors.light.actionPrimaryFg,
    actionPrimaryFill: _actionPrimaryGradient,
  );

  static final dark = AppActionColors(
    actionPrimary: AppColors.dark.actionPrimary,
    actionPrimaryFg: AppColors.dark.actionPrimaryFg,
    actionPrimaryFill: _actionPrimaryGradientDark,
  );

  /// Solid primary colour (Material `ColorScheme.primary`, accents).
  final Color actionPrimary;

  /// Text/icon colour on top of [actionPrimary] / [actionPrimaryFill].
  final Color actionPrimaryFg;

  /// Primary button background. A solid fill is a two-stop gradient of the
  /// same colour, so painting code is identical in both modes.
  final Gradient actionPrimaryFill;

  @override
  AppActionColors copyWith({
    Color? actionPrimary,
    Color? actionPrimaryFg,
    Gradient? actionPrimaryFill,
  }) {
    return AppActionColors(
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryFg: actionPrimaryFg ?? this.actionPrimaryFg,
      actionPrimaryFill: actionPrimaryFill ?? this.actionPrimaryFill,
    );
  }

  @override
  AppActionColors lerp(ThemeExtension<AppActionColors>? other, double t) {
    if (other is! AppActionColors) return this;
    return AppActionColors(
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionPrimaryFg: Color.lerp(actionPrimaryFg, other.actionPrimaryFg, t)!,
      actionPrimaryFill:
          Gradient.lerp(actionPrimaryFill, other.actionPrimaryFill, t) ??
          actionPrimaryFill,
    );
  }
}
