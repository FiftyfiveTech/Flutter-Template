import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Circular avatar showing a locally stored photo when [photoPath] is
/// set (and the file still exists), otherwise the initials of [name] —
/// or a generic person placeholder when there's no name to draw from.
/// Reads from disk only, so it renders identically offline.
class AhAvatar extends StatelessWidget {
  const AhAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.radius = 24,
  });

  final String name;
  final String? photoPath;
  final double radius;

  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final initialsText = initialsOf(name);
    final initials = initialsText.isEmpty
        ? Icon(
            Icons.person_outline,
            size: radius,
            color: AppColors.actionPrimaryFg,
          )
        : Text(
            initialsText,
            style: typography.body.copyWith(
              color: AppColors.actionPrimaryFg,
              fontWeight: FontWeight.w700,
            ),
          );
    final size = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.actionPrimary,
      child: photoPath == null
          ? initials
          : ClipOval(
              child: Image.file(
                File(photoPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                // Missing/corrupt file (e.g. wiped app storage) — fall
                // back to initials rather than a broken-image box.
                errorBuilder: (_, _, _) => Center(child: initials),
              ),
            ),
    );
  }
}
