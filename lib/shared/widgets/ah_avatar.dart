import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Circular avatar showing a locally stored photo when [photoPath] is
/// set (and the file still exists), otherwise the initials of [name] —
/// or a generic person placeholder when there's no name to draw from.
/// [photoUrl] (a remote photo, e.g. a guest's at the door) is used when
/// there's no local [photoPath]; it falls back to initials offline.
class AhAvatar extends StatelessWidget {
  const AhAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.photoUrl,
    this.radius = 24,
  });

  final String name;
  final String? photoPath;
  final String? photoUrl;
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
            color: context.colors.actionPrimaryFg,
          )
        : Text(
            initialsText,
            style: typography.body.copyWith(
              color: context.colors.actionPrimaryFg,
              fontWeight: FontWeight.w700,
            ),
          );
    final size = radius * 2;
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return CircleAvatar(
      radius: radius,
      backgroundColor: context.colors.actionPrimary,
      child: photoPath != null
          ? ClipOval(
              child: Image.file(
                File(photoPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                // Missing/corrupt file (e.g. wiped app storage) — fall
                // back to initials rather than a broken-image box.
                errorBuilder: (_, _, _) => Center(child: initials),
              ),
            )
          : photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                // Offline or a dead link: initials, not a broken image.
                errorBuilder: (_, _, _) => Center(child: initials),
              ),
            )
          : initials,
    );
  }
}
