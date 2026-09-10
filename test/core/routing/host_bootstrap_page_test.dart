import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:host_mobile_app/core/di/database_providers.dart';
import 'package:host_mobile_app/core/routing/host_bootstrap_page.dart';
import 'package:host_mobile_app/core/session/host_session.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_onboarding_progress.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_onboarding_step.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_onboarding_progress_providers.dart';

import '../../support/fakes.dart';

const _session = HostSession(
  accessToken: 'token',
  userId: 'u1',
  accountStatus: 'pending_review',
);

void main() {
  Future<void> pumpBootstrap(
    WidgetTester tester, {
    HostSession? session,
    HostOnboardingProgress? progress,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HostBootstrapPage(),
        ),
        GoRoute(
          path: '/host/landing',
          builder: (context, state) => const Scaffold(body: Text('Landing')),
        ),
        GoRoute(
          path: '/host/signup/host-type',
          builder: (context, state) => const Scaffold(body: Text('Host type')),
        ),
        GoRoute(
          path: '/host/signup/host-type/documents/verification',
          builder: (context, state) =>
              const Scaffold(body: Text('Verification')),
        ),
        GoRoute(
          path: '/host/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hostSessionLocalDatasourceProvider.overrideWithValue(
            FakeHostSessionLocalDatasource(initial: session),
          ),
          hostOnboardingProgressRepositoryProvider.overrideWithValue(
            FakeHostOnboardingProgressRepository(initial: progress),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no session resumes at H-00 Landing', (tester) async {
    await pumpBootstrap(tester);
    expect(find.text('Landing'), findsOneWidget);
  });

  testWidgets('a session with no saved progress resumes at H-05 Home', (
    tester,
  ) async {
    await pumpBootstrap(tester, session: _session);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('hostType progress resumes at H-02 · Host type', (tester) async {
    await pumpBootstrap(
      tester,
      session: _session,
      progress: const HostOnboardingProgress(step: HostOnboardingStep.hostType),
    );
    expect(find.text('Host type'), findsOneWidget);
  });

  testWidgets(
    'documents progress resumes at H-02 · Host type, not H-03 · Documents',
    (tester) async {
      await pumpBootstrap(
        tester,
        session: _session,
        progress: const HostOnboardingProgress(
          step: HostOnboardingStep.documents,
        ),
      );
      expect(find.text('Host type'), findsOneWidget);
    },
  );

  testWidgets('verification progress resumes at H-04 · Verification', (
    tester,
  ) async {
    await pumpBootstrap(
      tester,
      session: _session,
      progress: const HostOnboardingProgress(
        step: HostOnboardingStep.verification,
      ),
    );
    expect(find.text('Verification'), findsOneWidget);
  });

  testWidgets('home progress resumes at H-05 Home', (tester) async {
    await pumpBootstrap(
      tester,
      session: _session,
      progress: const HostOnboardingProgress(step: HostOnboardingStep.home),
    );
    expect(find.text('Home'), findsOneWidget);
  });
}
