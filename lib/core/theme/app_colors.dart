import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Semantic color tokens for the Host app's light theme.
///
/// Background/surface/text/status tokens mirror the `.theme-light` block in
/// `docs/design_systems/tokens/colors.css` (the shared paper/ink/teal/sun/
/// rose system). Action tokens instead carry the Host app's own dusty-rose
/// brand accent (replacing the shared system's cobalt). Raw values live in
/// [AppPalette]; this file only maps them to meaning.
abstract final class AppColors {
  // Background
  static const backgroundPrimary = AppPalette.paper100;
  static const backgroundSecondary = AppPalette.paper200;

  // Surface
  static const surfaceCard = AppPalette.paper050;
  static const surfaceRaised = AppPalette.white;
  static const scrim = AppPalette.blackAlpha55;

  // Border
  static const borderDefault = AppPalette.ink900Alpha07;
  static const borderStrong = AppPalette.ink900Alpha16;

  // Text
  static const textPrimary = AppPalette.ink900;
  static const textSecondary = AppPalette.ink500;
  static const textTertiary = AppPalette.ink400;
  static const textOnAction = AppPalette.white;

  // Action — Host brand accent (dusty rose), not the shared system's cobalt.
  static const actionPrimary = AppPalette.primary400;
  static const actionPrimaryHover = AppPalette.primary300;
  static const actionPrimaryPressed = AppPalette.primary500;
  static const actionPrimaryFg = AppPalette.white;
  static const actionSecondary = AppPalette.paper200;
  static const actionSecondaryFg = AppPalette.ink900;
  static const actionTertiaryFg = AppPalette.primary500;
  static const actionDestructive = AppPalette.rose500;

  // Status
  static const statusSuccess = AppPalette.teal600;
  static const statusWarning = AppPalette.sun600;
  static const statusError = AppPalette.rose500;
  static const statusInfo = AppPalette.primary400;

  // Trust
  static const trustVerified = AppPalette.teal600;
}

/// Primary-action tokens exposed through `ThemeData.extensions`, so the
/// primary button fill can be swapped (gradient vs solid, see
/// `AppTheme.buttonFill`) without widgets branching on the mode.
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

  static const light = AppActionColors(
    actionPrimary: AppColors.actionPrimary,
    actionPrimaryFg: AppColors.actionPrimaryFg,
    actionPrimaryFill: _actionPrimaryGradient,
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
