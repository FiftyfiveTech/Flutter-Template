import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/di/theme_providers.dart';
import 'package:host_mobile_app/core/theme/app_colors.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_home/presentation/widgets/host_home_bottom_nav.dart';

Widget _subject(AppButtonFill fill) {
  return MaterialApp(
    theme: AppTheme.lightWith(fill),
    home: Scaffold(
      bottomNavigationBar: HostHomeBottomNav(currentIndex: 0, onTap: (_) {}),
    ),
  );
}

/// The selected tab's pill — the only decorated box painted with a gradient.
Gradient _selectedPillFill(WidgetTester tester) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .map((d) => d.gradient)
      .whereType<Gradient>()
      .single;
}

void main() {
  test('buttons default to the gradient fill', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(buttonFillControllerProvider),
      AppButtonFill.gradient,
    );
  });

  testWidgets('selected tab is flat in the solid style', (tester) async {
    await tester.pumpWidget(_subject(AppButtonFill.solid));

    expect(_selectedPillFill(tester).colors, [
      AppColors.light.actionPrimary,
      AppColors.light.actionPrimary,
    ]);
  });

  testWidgets('selected tab follows the gradient style', (tester) async {
    await tester.pumpWidget(_subject(AppButtonFill.gradient));

    expect(_selectedPillFill(tester), AppActionColors.light.actionPrimaryFill);
  });
}
