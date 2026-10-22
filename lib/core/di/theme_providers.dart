import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../theme/app_theme.dart';
import '../theme/theme_mode_local_datasource.dart';
import 'database_providers.dart';

part 'theme_providers.g.dart';

@Riverpod(keepAlive: true)
ThemeModeLocalDatasource themeModeLocalDatasource(Ref ref) {
  return DriftThemeModeLocalDatasource(ref.watch(appDatabaseProvider));
}

/// The host's Appearance choice (H-12 · Profile), applied at the app root.
/// Defaults to [ThemeMode.light] until the host picks otherwise; the choice
/// is persisted so it survives restarts and sign-out.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.light;

  /// Loads the saved choice, if any. Awaited in `main` before the first
  /// frame so a dark-mode host never sees a light flash on launch.
  Future<void> hydrate() async {
    final saved = await ref.read(themeModeLocalDatasourceProvider).load();
    if (saved != null) state = saved;
  }

  void setMode(ThemeMode mode) {
    if (mode == state) return;
    state = mode;
    unawaited(ref.read(themeModeLocalDatasourceProvider).save(mode));
  }
}

/// How primary buttons (and the bottom nav's selected tab) are filled —
/// gradient by default. Flipped from the H-12 Profile test toggle to compare
/// against the solid fill; not persisted, so a restart returns to
/// [AppTheme.buttonFill].
@Riverpod(keepAlive: true)
class ButtonFillController extends _$ButtonFillController {
  @override
  AppButtonFill build() => AppTheme.buttonFill;

  void setFill(AppButtonFill fill) => state = fill;
}
