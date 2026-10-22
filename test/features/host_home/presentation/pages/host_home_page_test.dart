import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:host_mobile_app/core/di/database_providers.dart';
import 'package:host_mobile_app/core/di/session_providers.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/session/host_session.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_home/domain/entities/host_home_event.dart';
import 'package:host_mobile_app/features/host_home/domain/entities/host_home_summary.dart';
import 'package:host_mobile_app/features/host_home/domain/repositories/host_home_repository.dart';
import 'package:host_mobile_app/features/host_home/presentation/controllers/host_home_api_providers.dart';
import 'package:host_mobile_app/features/host_home/presentation/pages/host_home_page.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_status.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_verification_status.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_document_status_repository.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_document_status_api_providers.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile.dart';
import 'package:host_mobile_app/features/host_profile/domain/usecases/load_host_profile.dart';
import 'package:host_mobile_app/features/host_profile/presentation/controllers/host_profile_providers.dart';

import '../../../../support/fakes.dart';

/// Stands in for the cache-first profile load; defaults to "no profile"
/// so the header falls back to the summary/session name.
class _FakeLoadHostProfile implements LoadHostProfileUseCase {
  _FakeLoadHostProfile([this.result = const Err(NetworkFailure())]);

  final Result<HostProfile> result;
  var calls = 0;

  @override
  Future<Result<HostProfile>> call(String userId) async {
    calls++;
    return result;
  }
}

class _FakeHostHomeRepository implements HostHomeRepository {
  _FakeHostHomeRepository();

  final HostHomeSummary summary = const HostHomeSummary(
    hostName: 'Cellar Door Collective',
    // Mirrors the real placeholder datasource — verification must come
    // from the document-review status, not this flag.
    isVerified: false,
    savedVenuesCount: 2,
    events: [
      HostHomeEvent(
        id: 'evt-1',
        title: 'Blind Wine & Bad Takes',
        formattedSchedule: 'Thu, 12 Sep · 8:00 PM · Toit, Indiranagar',
        status: HostEventStatus.upcoming,
        soldCount: 12,
        capacity: 32,
      ),
      HostHomeEvent(
        id: 'evt-2',
        title: 'Pottery & Small Talk',
        formattedSchedule: 'Sat, 14 Sep · 6:30 PM · Vasanth Nagar',
        status: HostEventStatus.draft,
        soldCount: 8,
        capacity: 24,
      ),
      HostHomeEvent(
        id: 'evt-3',
        title: 'Board Game Night',
        formattedSchedule: 'Sun, 30 Aug · 7:00 PM · Koramangala',
        status: HostEventStatus.completed,
        soldCount: 28,
        capacity: 28,
      ),
    ],
  );

  @override
  Future<Result<HostHomeSummary>> getHomeSummary() async => Ok(summary);
}

class _FakeDocumentStatusRepository implements HostDocumentStatusRepository {
  _FakeDocumentStatusRepository(this.result);

  final Result<List<HostDocumentStatus>> result;

  @override
  Future<Result<List<HostDocumentStatus>>> getDocumentsStatus() async => result;
}

const _approved = HostDocumentStatus(
  docType: null,
  status: HostDocumentVerificationStatus.approved,
);
const _pending = HostDocumentStatus(
  docType: null,
  status: HostDocumentVerificationStatus.pending,
);

void main() {
  Widget buildSubject({
    _FakeHostHomeRepository? repository,
    _FakeLoadHostProfile? loadProfile,
    Result<List<HostDocumentStatus>> documents = const Ok([
      _approved,
      _approved,
    ]),
  }) {
    final repo = repository ?? _FakeHostHomeRepository();
    final router = GoRouter(
      initialLocation: '/host/home',
      routes: [
        GoRoute(
          path: '/host/home',
          builder: (context, state) => const HostHomePage(),
        ),
        GoRoute(
          path: '/host/events/new',
          builder: (context, state) =>
              const Scaffold(body: Text('New event page')),
        ),
        GoRoute(
          path: '/host/events/:id',
          builder: (context, state) => Scaffold(
            body: Text('Event details page ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        hostHomeRepositoryProvider.overrideWithValue(repo),
        hostDocumentStatusRepositoryProvider.overrideWithValue(
          _FakeDocumentStatusRepository(documents),
        ),
        hostSessionLocalDatasourceProvider.overrideWithValue(
          FakeHostSessionLocalDatasource(),
        ),
        loadHostProfileUseCaseProvider.overrideWithValue(
          loadProfile ?? _FakeLoadHostProfile(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets('renders header, verification banner, and event cards', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Header
    expect(find.text('Cellar Door Collective'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verification badge, driven by the document-review status
    expect(find.text('Verified'), findsOneWidget);

    // Section header
    expect(find.text('YOUR EVENTS — TAP TO EDIT'), findsOneWidget);

    // Event cards & statuses
    expect(find.text('Blind Wine & Bad Takes'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('12 of 32 sold'), findsOneWidget);

    expect(find.text('Pottery & Small Talk'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('8 of 24 sold'), findsOneWidget);

    expect(find.text('Board Game Night'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('28 of 28 sold'), findsOneWidget);

    // Bottom Navigation
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('shows Pending while any document is still in review', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(documents: const Ok([_approved, _pending])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);
  });

  testWidgets('falls back to not verified when the status fetch fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(documents: const Err(NetworkFailure(message: 'offline'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('tapping event card navigates to its event details screen', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Blind Wine & Bad Takes'));
    await tester.pumpAndSettle();

    expect(find.text('Event details page evt-1'), findsOneWidget);
  });

  testWidgets('tapping Add Event button navigates to the new event screen', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('New event page'), findsOneWidget);
  });

  testWidgets('tapping bottom nav tab switches tab and shows message', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pump();

    expect(find.text('Payouts — coming soon'), findsOneWidget);
  });

  testWidgets('header shows the profile loaded after sign-in', (tester) async {
    final loadProfile = _FakeLoadHostProfile(
      const Ok(HostProfile(userId: 'u1', hostName: 'Fetched Collective')),
    );
    await tester.pumpWidget(buildSubject(loadProfile: loadProfile));
    await tester.pumpAndSettle();

    expect(find.text('Fetched Collective'), findsOneWidget);
    expect(loadProfile.calls, 1);
  });

  testWidgets('header follows a business name changed via Edit profile', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Cellar Door Collective'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HostHomePage)),
    );
    container
        .read(hostSessionControllerProvider.notifier)
        .setSession(
          const HostSession(
            accessToken: 't',
            userId: 'u1',
            accountStatus: 'active',
            businessName: 'Renamed Collective',
          ),
        );
    await tester.pump();

    expect(find.text('Renamed Collective'), findsOneWidget);
    expect(find.text('Cellar Door Collective'), findsNothing);
  });
}
