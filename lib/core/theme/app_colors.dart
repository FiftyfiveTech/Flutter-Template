import 'package:flutter/material.dart';

/// Semantic color tokens for the Host app's light theme.
///
/// Background/surface/text/status tokens mirror the `.theme-light` block in
/// `docs/design_systems/tokens/colors.css` (the shared paper/ink/teal/sun/
/// rose system). Action tokens instead carry the Host app's own dusty-rose
/// brand accent (replacing the shared system's cobalt) — the same brand hue
/// the dark theme applies, shifted darker here for contrast against light
/// surfaces and white button text.
abstract final class AppColors {
  // Background
  static const backgroundPrimary = Color(0xFFF2F1EE); // --paper-100
  static const backgroundSecondary = Color(0xFFEBEAE6); // --paper-200

  // Surface
  static const surfaceCard = Color(0xFFFBFBFA); // --paper-050
  static const surfaceRaised = Color(0xFFFFFFFF);

  // Border
  static const borderDefault = Color(0x121A1A18); // rgba(26,26,24,.07)
  static const borderStrong = Color(0x291A1A18); // rgba(26,26,24,.16)

  // Text
  static const textPrimary = Color(0xFF1A1A18); // --ink-900
  static const textSecondary = Color(0xFF66655F); // --ink-500
  static const textTertiary = Color(0xFF8A8983); // --ink-400
  static const textOnAction = Color(0xFFFFFFFF);

  // Action — Host brand accent (dusty rose), not the shared system's cobalt.
  static const actionPrimary = Color(0xFF8B4F63);
  static const actionPrimaryHover = Color(0xFFA3677A);
  static const actionPrimaryPressed = Color(0xFF6B3A4D);
  static const actionPrimaryFg = Color(0xFFFFFFFF);
  static const actionSecondary = Color(0xFFEBEAE6); // --paper-200
  static const actionSecondaryFg = Color(0xFF1A1A18); // --ink-900
  static const actionTertiaryFg = Color(0xFF6B3A4D);
  static const actionDestructive = Color(0xFFC0344E); // --rose-500

  // Status
  static const statusSuccess = Color(0xFF0F766E); // --teal-600
  static const statusWarning = Color(0xFFA16207); // --sun-600
  static const statusError = Color(0xFFC0344E); // --rose-500
  static const statusInfo = Color(0xFF8B4F63);

  // Trust
  static const trustVerified = Color(0xFF0F766E); // --teal-600
}
