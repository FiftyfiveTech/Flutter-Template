import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A single shimmering placeholder block — used to show the shape of
/// content that's still loading (a card, a line of text) instead of an
/// empty/"no data" state that would be misleading while a fetch is still
/// in flight. No shimmer package exists in this repo yet; this is a
/// self-contained sweep built on [ShaderMask], not worth a dependency for.
class AhShimmerBox extends StatefulWidget {
  const AhShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<AhShimmerBox> createState() => _AhShimmerBoxState();
}

class _AhShimmerBoxState extends State<AhShimmerBox>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusSm);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final sweep = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 - sweep * 2, 0),
              end: Alignment(1 - sweep * 2, 0),
              colors: const [
                AppColors.borderDefault,
                AppColors.textTertiary,
                AppColors.borderDefault,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.borderDefault,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
