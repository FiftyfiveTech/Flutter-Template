import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:host_mobile_app/core/di/database_providers.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/city.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_signup_result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_signup_repository.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/usecases/get_cities.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/city_search_providers.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_onboarding_progress_providers.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_signup_api_providers.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/pages/host_signup_page.dart';
import 'package:host_mobile_app/shared/widgets/ah_button.dart';

import '../../../../support/fakes.dart';

class _FakeGetCitiesUseCase implements GetCitiesUseCase {
  const _FakeGetCitiesUseCase();

  @override
  Future<Result<List<City>>> call() async {
    return const Ok([
      City(
        id: 'city-1',
        name: 'Chennai city',
        state: 'Tamil Nadu',
        country: 'India',
      ),
    ]);
  }
}

class _FakeHostSignupRepository implements HostSignupRepository {
  _FakeHostSignupRepository(this._result);
  final Result<HostSignupResult> _result;

  @override
  Future<Result<HostSignupResult>> signup(draft) async => _result;
}

void main() {
  Widget buildSubject({
    Result<HostSignupResult> signupResult = const Ok(
      HostSignupResult(
        accessToken: 'token',
        userId: 'u1',
        accountStatus: 'active',
      ),
    ),
  }) {
    return ProviderScope(
      overrides: [
        getCitiesUseCaseProvider.overrideWithValue(
          const _FakeGetCitiesUseCase(),
        ),
        hostSignupRepositoryProvider.overrideWithValue(
          _FakeHostSignupRepository(signupResult),
        ),
        hostSessionLocalDatasourceProvider.overrideWithValue(
          FakeHostSessionLocalDatasource(),
        ),
        hostOnboardingProgressRepositoryProvider.overrideWithValue(
          FakeHostOnboardingProgressRepository(),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HostSignupPage()),
    );
  }

  Widget buildRoutedSubject({
    Result<HostSignupResult> signupResult = const Ok(
      HostSignupResult(
        accessToken: 'token',
        userId: 'u1',
        accountStatus: 'active',
      ),
    ),
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HostSignupPage()),
        GoRoute(
          path: '/host/signup/host-type',
          builder: (context, state) =>
              const Scaffold(body: Text('Host type page')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        getCitiesUseCaseProvider.overrideWithValue(
          const _FakeGetCitiesUseCase(),
        ),
        hostSignupRepositoryProvider.overrideWithValue(
          _FakeHostSignupRepository(signupResult),
        ),
        hostSessionLocalDatasourceProvider.overrideWithValue(
          FakeHostSessionLocalDatasource(),
        ),
        hostOnboardingProgressRepositoryProvider.overrideWithValue(
          FakeHostOnboardingProgressRepository(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets('renders the four signup fields and a Continue button', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Host signup'), findsOneWidget);
    expect(find.text('Business or organiser name'), findsOneWidget);
    expect(find.text('Contact phone'), findsOneWidget);
    expect(find.text('Contact email'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.widgetWithText(AhButton, 'Continue'), findsOneWidget);
  });

  testWidgets('shows field errors when Continue is tapped with empty fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.widgetWithText(AhButton, 'Continue'));
    await tester.pump();

    expect(find.text('Enter a business or organiser name'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Select a city'), findsOneWidget);
  });

  testWidgets('advances to host type once all fields are valid', (
    tester,
  ) async {
    await tester.pumpWidget(buildRoutedSubject());

    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Cellar Door Collective'),
      'Cellar Door Collective',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '+91 98765 43210'),
      '+919876543210',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'you@business.com'),
      'you@business.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Search for a city'),
      'Chennai',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chennai city'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AhButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a business or organiser name'), findsNothing);
    expect(find.text('Enter a valid phone number'), findsNothing);
    expect(find.text('Enter a valid email address'), findsNothing);
    expect(find.text('Select a city'), findsNothing);
    expect(find.text('Host type page'), findsOneWidget);
  });

  testWidgets(
    'shows the submit error and stays on the page when signup fails',
    (tester) async {
      await tester.pumpWidget(
        buildRoutedSubject(
          signupResult: const Err(NetworkFailure(message: 'Signup failed.')),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Cellar Door Collective'),
        'Cellar Door Collective',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '+91 98765 43210'),
        '+919876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'you@business.com'),
        'you@business.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Search for a city'),
        'Chennai',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chennai city'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AhButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Signup failed.'), findsOneWidget);
      expect(find.text('Host type page'), findsNothing);
    },
  );
}
