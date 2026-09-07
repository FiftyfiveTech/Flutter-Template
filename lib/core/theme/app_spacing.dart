import 'package:flutter/widgets.dart';

/// Spacing/radius scale, mirroring `docs/design_systems/tokens/spacing.css` and
/// `radius.css`'s 4pt grid.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  // Layout tokens
  static const gutter = 20.0;
  static const sectionGap = 32.0;
  static const cardGap = 12.0;
  static const touchTargetMin = 44.0;
  static const touchTargetComfortable = 48.0;

  // Radii
  static const radiusSm = 8.0;
  static const radiusMd = 10.0;
  static const radiusLg = 14.0;
  static const radiusCard = 16.0;
  static const radiusXl = 20.0;
  static const radiusSheet = 24.0;
  static const radiusPill = 999.0;
  static const radiusFull = 999.0;

  // Ready-to-use SizedBox spacers
  static const spacerXs = SizedBox(height: xs, width: xs);
  static const spacerSm = SizedBox(height: sm, width: sm);
  static const spacerMd = SizedBox(height: md, width: md);
  static const spacerLg = SizedBox(height: lg, width: lg);
}
