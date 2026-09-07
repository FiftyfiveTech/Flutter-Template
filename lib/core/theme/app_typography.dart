import 'package:flutter/material.dart';

/// Type scale, mirroring `docs/design_systems/tokens/typography.css`.
/// Families are wired in `AppTheme` via `google_fonts` (Bricolage Grotesque for
/// display/h1/h2, Be Vietnam Pro for everything else).
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.bodyLg,
    required this.body,
    required this.bodySm,
    required this.caption,
    required this.label,
  });

  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle bodyLg;
  final TextStyle body;
  final TextStyle bodySm;
  final TextStyle caption;
  final TextStyle label;

  @override
  AppTypography copyWith({
    TextStyle? display,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? bodyLg,
    TextStyle? body,
    TextStyle? bodySm,
    TextStyle? caption,
    TextStyle? label,
  }) {
    return AppTypography(
      display: display ?? this.display,
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      bodyLg: bodyLg ?? this.bodyLg,
      body: body ?? this.body,
      bodySm: bodySm ?? this.bodySm,
      caption: caption ?? this.caption,
      label: label ?? this.label,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
    );
  }
}
