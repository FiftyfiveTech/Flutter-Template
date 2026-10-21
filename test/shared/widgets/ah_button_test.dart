import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/theme/app_colors.dart';
import 'package:host_mobile_app/core/theme/app_palette.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/shared/widgets/ah_button.dart';

void main() {
  Widget buildSubject(
    Widget child, {
    AppButtonFill fill = AppButtonFill.gradient,
  }) {
    return MaterialApp(
      theme: AppTheme.lightWith(fill),
      home: Scaffold(body: Center(child: child)),
    );
  }

  Gradient primaryFill(WidgetTester tester) {
    final ink = tester.widget<Ink>(
      find.descendant(of: find.byType(AhButton), matching: find.byType(Ink)),
    );
    return (ink.decoration! as BoxDecoration).gradient!;
  }

  double opacityOf(WidgetTester tester) {
    return tester
        .widget<Opacity>(
          find.descendant(
            of: find.byType(AhButton),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
  }

  testWidgets('primary paints the palette gradient in gradient mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(AhButton(label: 'Continue', onPressed: () {})),
    );

    expect(primaryFill(tester).colors, const [
      AppPalette.primaryGradientTop,
      AppPalette.primaryGradientMid,
      AppPalette.primaryGradientBottom,
    ]);
  });

  testWidgets('primary paints a flat actionPrimary fill in solid mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        AhButton(label: 'Continue', onPressed: () {}),
        fill: AppButtonFill.solid,
      ),
    );

    expect(primaryFill(tester).colors, const [
      AppColors.actionPrimary,
      AppColors.actionPrimary,
    ]);
  });

  testWidgets('theme maps ColorScheme.primary to actionPrimary', (
    tester,
  ) async {
    final theme = AppTheme.lightWith(AppButtonFill.gradient);

    expect(theme.colorScheme.primary, AppColors.actionPrimary);
    expect(theme.colorScheme.onPrimary, AppColors.actionPrimaryFg);
  });

  testWidgets('enabled primary fires onPressed at full opacity', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      buildSubject(AhButton(label: 'Continue', onPressed: () => taps++)),
    );

    await tester.tap(find.text('Continue'));

    expect(taps, 1);
    expect(opacityOf(tester), 1);
  });

  testWidgets('disabled primary is dimmed and not tappable', (tester) async {
    await tester.pumpWidget(
      buildSubject(const AhButton(label: 'Continue', onPressed: null)),
    );

    expect(opacityOf(tester), AhButton.disabledOpacity);
    expect(
      tester
          .widget<InkWell>(
            find.descendant(
              of: find.byType(AhButton),
              matching: find.byType(InkWell),
            ),
          )
          .onTap,
      isNull,
    );
  });

  testWidgets('loading primary shows a spinner and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      buildSubject(
        AhButton(label: 'Continue', onPressed: () => taps++, isLoading: true),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(opacityOf(tester), 1);

    await tester.tap(find.byType(AhButton));

    expect(taps, 0);
  });
}
