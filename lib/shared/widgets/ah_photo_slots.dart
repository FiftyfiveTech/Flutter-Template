import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A row of fixed, equally-sized tappable photo slots — used wherever a
/// feature needs "pick up to N photos, show a placeholder for empty ones"
/// (e.g. venue photos). Each slot shows the picked image, or a camera
/// placeholder with its 1-based [label] when empty.
class AhPhotoSlots extends StatelessWidget {
  const AhPhotoSlots({
    super.key,
    required this.count,
    required this.photoPaths,
    required this.onTapSlot,
  });

  final int count;
  final List<String> photoPaths;
  final ValueChanged<int> onTapSlot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) AppSpacing.spacerSm,
          Expanded(
            child: _PhotoSlot(
              index: i,
              path: i < photoPaths.length ? photoPaths[i] : null,
              onTap: () => onTapSlot(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.index,
    required this.path,
    required this.onTap,
  });

  final int index;
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final hasPhoto = path != null && path!.isNotEmpty;
    final borderRadius = BorderRadius.circular(AppSpacing.radiusLg);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.borderDefault),
            image: hasPhoto
                ? DecorationImage(
                    image: FileImage(File(path!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: hasPhoto
              ? null
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    AppSpacing.spacerXs,
                    Text(
                      'Photo ${index + 1}',
                      style: typography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
