import 'package:flutter/material.dart';

/// Semantic color tokens for the Host app's dark theme.
///
/// The Host app renders with the violet/rose-tinted override that
/// `After Hours - Host screens.dc.html` applies on top of the shared
/// `docs/design_systems/tokens/colors.css` tokens (`#dc-root,.theme-dark`
/// block) — background, surface, text and the action-primary accent all
/// shift together, consistently, across every Host screen in that file.
/// Tokens not touched by that override (secondary/tertiary actions, status,
/// trust) fall back to the shared coal/cobalt/teal system unchanged.
abstract final class AppColors {
  // Background
  static const backgroundPrimary = Color(0xFF0B0A0D);
  static const backgroundSecondary = Color(
    0xFF0E0E0D,
  ); // --coal-950 (not overridden)

  // Surface
  // True token is a radial gradient (#332a44 -> #241f33 -> #1a1626 -> #130f1c);
  // this is a flat approximation for call sites that don't render a gradient yet.
  static const surfaceCard = Color(0xFF241F33);
  static const surfaceRaised = Color(0xFF2A2A28); // --coal-700 (not overridden)

  // Border
  static const borderDefault = Color(0x1AFFFFFF); // rgba(255,255,255,.1)
  static const borderStrong = Color(
    0x29FFFFFF,
  ); // rgba(255,255,255,.16) (not overridden)

  // Text
  static const textPrimary = Color(0xFFF4EFF9);
  static const textSecondary = Color(0xADF4EFF9); // rgba(244,239,249,.68)
  static const textTertiary = Color(0x80F4EFF9); // rgba(244,239,249,.5)
  static const textOnAction = Color(0xFFFFFFFF);

  // Action
  static const actionPrimary = Color(0xFFC17B90);
  static const actionPrimaryHover = Color(0xFFD497A8);
  static const actionPrimaryPressed = Color(
    0xFFA3677A,
  ); // darkened; no explicit token override
  static const actionPrimaryFg = Color(0xFFFFFFFF);
  static const actionSecondary = Color(
    0xFF2A2A28,
  ); // --coal-700 (not overridden)
  static const actionSecondaryFg = Color(0xFFF5F5F2);
  static const actionTertiaryFg = Color(
    0xFF8B97EE,
  ); // --cobalt-300 (not overridden)
  static const actionDestructive = Color(
    0xFFF2637E,
  ); // --rose-300 (not overridden)

  // Status
  static const statusSuccess = Color(0xFF5BD1B0); // --teal-300
  static const statusWarning = Color(0xFFE9C46A); // --sun-300
  static const statusError = Color(0xFFF2637E); // --rose-300
  static const statusInfo = Color(0xFF8B97EE); // --cobalt-300

  // Trust
  static const trustVerified = Color(0xFF5BD1B0); // --teal-300
}
