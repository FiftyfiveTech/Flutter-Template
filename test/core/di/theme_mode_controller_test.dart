import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/database/app_database.dart';
import 'package:host_mobile_app/core/di/database_providers.dart';
import 'package:host_mobile_app/core/di/theme_providers.dart';
import 'package:host_mobile_app/core/theme/app_colors.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';

void main() {
  late AppDatabase db;

  ProviderContainer newContainer() {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('defaults to light when the host never picked a mode', () async {
    final container = newContainer();
    await container.read(themeModeControllerProvider.notifier).hydrate();

    expect(container.read(themeModeControllerProvider), ThemeMode.light);
  });

  for (final mode in [ThemeMode.dark, ThemeMode.system, ThemeMode.light]) {
    test('remembers ${mode.name} across app restarts', () async {
      final first = newContainer();
      first.read(themeModeControllerProvider.notifier)
        ..setMode(ThemeMode.dark)
        ..setMode(mode);
      expect(first.read(themeModeControllerProvider), mode);
      await pumpEventQueue();

      final restarted = newContainer();
      await restarted.read(themeModeControllerProvider.notifier).hydrate();
      expect(restarted.read(themeModeControllerProvider), mode);
    });
  }

  testWidgets('each theme carries its own colour tokens', (tester) async {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.light.extension<AppColors>(), AppColors.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.dark.extension<AppColors>(), AppColors.dark);
    expect(
      AppTheme.dark.scaffoldBackgroundColor,
      AppColors.dark.backgroundPrimary,
    );
  });
}
