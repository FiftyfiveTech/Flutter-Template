import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  // Custom radii
  static const radiusSm = 4.0;
  static const radiusMd = 8.0;
  static const radiusLg = 16.0;
  static const radiusFull = 9999.0;
  
  // Ready-to-use SizedBox spacers
  static const spacerXs = SizedBox(height: xs, width: xs);
  static const spacerSm = SizedBox(height: sm, width: sm);
  static const spacerMd = SizedBox(height: md, width: md);
  static const spacerLg = SizedBox(height: lg, width: lg);
}
