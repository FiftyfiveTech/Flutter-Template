import 'package:flutter/material.dart';

@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.bodySm,
    required this.bodyMd,
    required this.bodyLg,
    required this.headingSm,
    required this.headingMd,
    required this.headingLg,
  });

  final TextStyle bodySm;
  final TextStyle bodyMd;
  final TextStyle bodyLg;
  final TextStyle headingSm;
  final TextStyle headingMd;
  final TextStyle headingLg;

  @override
  AppTypography copyWith({
    TextStyle? bodySm,
    TextStyle? bodyMd,
    TextStyle? bodyLg,
    TextStyle? headingSm,
    TextStyle? headingMd,
    TextStyle? headingLg,
  }) {
    return AppTypography(
      bodySm: bodySm ?? this.bodySm,
      bodyMd: bodyMd ?? this.bodyMd,
      bodyLg: bodyLg ?? this.bodyLg,
      headingSm: headingSm ?? this.headingSm,
      headingMd: headingMd ?? this.headingMd,
      headingLg: headingLg ?? this.headingLg,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      bodyMd: TextStyle.lerp(bodyMd, other.bodyMd, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      headingSm: TextStyle.lerp(headingSm, other.headingSm, t)!,
      headingMd: TextStyle.lerp(headingMd, other.headingMd, t)!,
      headingLg: TextStyle.lerp(headingLg, other.headingLg, t)!,
    );
  }
}
