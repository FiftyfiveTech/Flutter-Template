import 'package:flutter/painting.dart';

/// Raw colour values — the only file in `lib/` allowed to contain hex
/// literals. Widgets never read this directly; they go through the semantic
/// tokens in `AppColors` / `AppActionColors`.
///
/// Neutral/status swatches mirror `docs/design_systems/tokens/colors.css`. The
/// primary swatch is the Host app's own dusty-rose brand accent (replacing the
/// shared system's cobalt).
abstract final class AppPalette {
  // Brand primary (dusty rose). `primary400` is the base brand colour —
  // changing it re-colours every primary button, switch and accent.
  static const primary300 = Color(0xFFA3677A);
  static const primary400 = Color(0xFF8B4F63);
  static const primary500 = Color(0xFF6B3A4D);

  // Primary button gradient stops (top → bottom).
  static const primaryGradientTop = primary300;
  static const primaryGradientMid = primary400;
  static const primaryGradientBottom = primary500;

  // Paper
  static const paper050 = Color(0xFFFBFBFA);
  static const paper100 = Color(0xFFF2F1EE);
  static const paper200 = Color(0xFFEBEAE6);
  static const white = Color(0xFFFFFFFF);

  // Ink
  static const ink900 = Color(0xFF1A1A18);
  static const ink500 = Color(0xFF66655F);
  static const ink400 = Color(0xFF8A8983);
  static const ink900Alpha07 = Color(0x121A1A18); // rgba(26,26,24,.07)
  static const ink900Alpha16 = Color(0x291A1A18); // rgba(26,26,24,.16)
  static const blackAlpha55 = Color(0x8C000000);

  // Status hues
  static const teal600 = Color(0xFF0F766E);
  static const sun600 = Color(0xFFA16207);
  static const rose500 = Color(0xFFC0344E);
}
