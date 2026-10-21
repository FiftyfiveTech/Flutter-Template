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
  // `primary200` is the dark theme's legible-on-coal accent tint.
  static const primary200 = Color(0xFFC48E9F);
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

  // Coal — the dark theme's surfaces and secondary type.
  static const coal950 = Color(0xFF0E0E0D);
  static const coal900 = Color(0xFF151514);
  static const coal800 = Color(0xFF1F1F1E);
  static const coal700 = Color(0xFF2A2A28);
  static const coal400 = Color(0xFF6E6E6A);
  static const coal300 = Color(0xFF9A9A95);
  static const coalText = Color(0xFFF5F5F2);
  static const whiteAlpha07 = Color(0x12FFFFFF); // rgba(255,255,255,.07)
  static const whiteAlpha16 = Color(0x29FFFFFF); // rgba(255,255,255,.16)
  static const coalScrim = Color(0xB8080807); // rgba(8,8,7,.72)

  // Status hues
  static const teal600 = Color(0xFF0F766E);
  static const sun600 = Color(0xFFA16207);
  static const rose500 = Color(0xFFC0344E);

  // Status hues tuned for dark surfaces.
  static const teal300 = Color(0xFF5BD1B0);
  static const sun300 = Color(0xFFE9C46A);
  static const rose300 = Color(0xFFF2637E);
}
