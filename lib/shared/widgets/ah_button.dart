import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Button style variants mirroring the design system's `Button` component.
enum AhButtonVariant { primary, secondary, tertiary, destructive }

/// The app's standard button — primary (accent fill, gradient or solid per
/// `buttonFillControllerProvider`), secondary (filled neutral), tertiary (text-only) or
/// destructive. Used for every CTA across the app so sizing/color/radius stay
/// consistent without re-styling per screen.
///
/// A null [onPressed] renders the disabled state; [isLoading] swaps the label
/// for a spinner and ignores taps.
class AhButton extends StatelessWidget {
  const AhButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AhButtonVariant.primary,
    this.fullWidth = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AhButtonVariant variant;
  final bool fullWidth;
  final bool isLoading;

  static const disabledOpacity = 0.4;
  static const _spinnerSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final labelStyle = typography.body.copyWith(fontWeight: FontWeight.w600);
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final tap = isLoading ? null : onPressed;

    Widget content(Color color) => isLoading
        ? SizedBox.square(
            dimension: _spinnerSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    final Widget button = switch (variant) {
      AhButtonVariant.primary => _PrimaryFill(
        onPressed: tap,
        isDisabled: onPressed == null,
        radius: radius,
        labelStyle: labelStyle,
        content: content,
      ),
      AhButtonVariant.secondary => ElevatedButton(
        onPressed: tap,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.actionSecondary,
          foregroundColor: context.colors.actionSecondaryFg,
          textStyle: labelStyle,
          shape: shape,
        ),
        child: content(context.colors.actionSecondaryFg),
      ),
      AhButtonVariant.tertiary => TextButton(
        onPressed: tap,
        style: TextButton.styleFrom(
          foregroundColor: context.colors.actionTertiaryFg,
          textStyle: labelStyle,
          shape: shape,
        ),
        child: content(context.colors.actionTertiaryFg),
      ),
      AhButtonVariant.destructive => ElevatedButton(
        onPressed: tap,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.actionDestructive,
          foregroundColor: context.colors.actionPrimaryFg,
          textStyle: labelStyle,
          shape: shape,
        ),
        child: content(context.colors.actionPrimaryFg),
      ),
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppSpacing.touchTargetComfortable,
      child: button,
    );
  }
}

/// Paints `AppActionColors.actionPrimaryFill` behind an ink-splash tap target.
/// Solid vs gradient is decided by the theme, never here.
class _PrimaryFill extends StatelessWidget {
  const _PrimaryFill({
    required this.onPressed,
    required this.isDisabled,
    required this.radius,
    required this.labelStyle,
    required this.content,
  });

  final VoidCallback? onPressed;
  final bool isDisabled;
  final BorderRadius radius;
  final TextStyle labelStyle;
  final Widget Function(Color color) content;

  @override
  Widget build(BuildContext context) {
    final action = Theme.of(context).extension<AppActionColors>()!;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Opacity(
        opacity: isDisabled ? AhButton.disabledOpacity : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: action.actionPrimaryFill,
              borderRadius: radius,
            ),
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Center(
                  widthFactor: 1,
                  child: DefaultTextStyle(
                    style: labelStyle.copyWith(color: action.actionPrimaryFg),
                    child: content(action.actionPrimaryFg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
