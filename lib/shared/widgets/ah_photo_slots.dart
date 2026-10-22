import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// What one [AhPhotoSlots] slot should currently render. All state lives in
/// the caller's controller — this widget only paints what it's told.
enum AhPhotoSlotStatus { empty, uploading, uploaded, error }

/// Plain data for a single slot. [localPath] — when present — is always
/// preferred for display: it's a file already on disk, so it can't fail to
/// load the way a presigned [networkUrl] can (e.g. if it points at a host
/// unreachable from this device). [networkUrl] is only used as a fallback,
/// for photos with no local file at all (loaded from an existing venue).
class AhPhotoSlotData {
  const AhPhotoSlotData({
    this.status = AhPhotoSlotStatus.empty,
    this.localPath,
    this.networkUrl,
    this.errorMessage,
  });

  final AhPhotoSlotStatus status;
  final String? localPath;
  final String? networkUrl;
  final String? errorMessage;
}

/// Fixed size of every slot, regardless of how many are shown — slots never
/// shrink to fit; the row scrolls horizontally once they overflow instead.
const _slotSize = 96.0;

/// A horizontally-scrollable row of fixed-size tappable photo slots — used
/// wherever a feature needs "pick up to N photos, show a placeholder for
/// empty ones" (e.g. venue photos). Each slot shows the picked/uploaded
/// image, an upload spinner, a retry affordance on error, or a camera
/// placeholder with its 1-based label when empty.
///
/// A null [onTapSlot] makes the row read-only: slots can't be tapped, but
/// the row still scrolls — unlike wrapping it in an `IgnorePointer`.
///
/// A non-null [onRemoveSlot] adds a remove (×) button to the top corner of
/// every non-empty slot; leave it null wherever photos can't be changed.
class AhPhotoSlots extends StatelessWidget {
  const AhPhotoSlots({
    super.key,
    required this.count,
    required this.slots,
    required this.onTapSlot,
    this.onRemoveSlot,
  });

  final int count;
  final List<AhPhotoSlotData> slots;
  final ValueChanged<int>? onTapSlot;
  final ValueChanged<int>? onRemoveSlot;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) AppSpacing.spacerSm,
            SizedBox(
              width: _slotSize,
              child: _PhotoSlot(
                index: i,
                data: i < slots.length ? slots[i] : const AhPhotoSlotData(),
                onTap: onTapSlot == null ? null : () => onTapSlot!(i),
                onRemove: onRemoveSlot == null ? null : () => onRemoveSlot!(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.index,
    required this.data,
    required this.onTap,
    required this.onRemove,
  });

  final int index;
  final AhPhotoSlotData data;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final borderRadius = BorderRadius.circular(AppSpacing.radiusLg);
    final hasLocalPreview =
        data.localPath != null && data.localPath!.isNotEmpty;
    final hasNetworkImage =
        data.networkUrl != null && data.networkUrl!.isNotEmpty;
    final hasImage = hasNetworkImage || hasLocalPreview;
    final isError = data.status == AhPhotoSlotStatus.error;
    final canRemove =
        onRemove != null && data.status != AhPhotoSlotStatus.empty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            _buildTile(context, typography, borderRadius, hasImage, isError),
            if (canRemove)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: _RemoveButton(index: index, onPressed: onRemove!),
              ),
          ],
        ),
        if (isError) ...[
          AppSpacing.spacerXs,
          Text(
            data.errorMessage ?? "Couldn't upload — tap to retry",
            style: typography.caption.copyWith(
              color: context.colors.statusError,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    AppTypography typography,
    BorderRadius borderRadius,
    bool hasImage,
    bool isError,
  ) {
    final hasLocalPreview =
        data.localPath != null && data.localPath!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: SizedBox(
          width: _slotSize,
          height: _slotSize,
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceCard,
              borderRadius: borderRadius,
              image: hasImage
                  ? DecorationImage(
                      image: hasLocalPreview
                          ? FileImage(File(data.localPath!)) as ImageProvider
                          : NetworkImage(data.networkUrl!),
                      fit: BoxFit.cover,
                      onError: (_, _) {},
                    )
                  : null,
            ),
            child: hasImage
                ? _buildOverlay(typography, context.colors)
                : CustomPaint(
                    painter: _DashedBorderPainter(
                      color: isError
                          ? context.colors.statusError
                          : context.colors.borderDefault,
                      radius: AppSpacing.radiusLg,
                    ),
                    child: _buildOverlay(typography, context.colors),
                  ),
          ),
        ),
      ),
    );
  }

  Widget? _buildOverlay(AppTypography typography, AppColors colors) {
    switch (data.status) {
      case AhPhotoSlotStatus.uploading:
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.actionPrimary,
            ),
          ),
        );
      case AhPhotoSlotStatus.error:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 22, color: colors.statusError),
              AppSpacing.spacerXs,
              Text(
                'Photo ${index + 1}',
                textAlign: TextAlign.center,
                style: typography.caption.copyWith(color: colors.statusError),
              ),
            ],
          ),
        );
      case AhPhotoSlotStatus.uploaded:
        return null;
      case AhPhotoSlotStatus.empty:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 22,
                color: colors.textTertiary,
              ),
              AppSpacing.spacerXs,
              Text(
                'Photo ${index + 1}',
                textAlign: TextAlign.center,
                style: typography.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'or browse files',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.caption.copyWith(
                  color: colors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// The small × in a filled slot's top corner. Drawn on the scrim colour
/// so it stays legible over any photo, in either theme.
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.index, required this.onPressed});

  final int index;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove photo ${index + 1}',
      excludeSemantics: true,
      child: Material(
        color: context.colors.scrim,
        shape: const CircleBorder(),
        child: InkWell(
          key: ValueKey('ah-photo-slot-remove-$index'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(
              Icons.close,
              size: 14,
              color: context.colors.textOnAction,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rect border for an empty/error photo slot, matching the
/// design's "drop zone" look. No dashed-border package exists in this repo
/// yet, and this is the only place that needs one.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _dashWidth = 5.0;
  static const _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
