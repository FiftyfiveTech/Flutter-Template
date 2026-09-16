import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_home/domain/entities/host_home_event.dart';
import 'package:host_mobile_app/features/host_home/domain/entities/host_home_summary.dart';
import 'package:host_mobile_app/features/host_home/domain/repositories/host_home_repository.dart';
import 'package:host_mobile_app/features/host_home/presentation/controllers/host_home_api_providers.dart';
import 'package:host_mobile_app/features/host_home/presentation/pages/host_home_page.dart';

class _FakeHostHomeRepository implements HostHomeRepository {
  _FakeHostHomeRepository();

  final HostHomeSummary summary = const HostHomeSummary(
    hostName: 'Cellar Door Collective',
    isVerified: true,
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

void main() {
  Widget buildSubject({_FakeHostHomeRepository? repository}) {
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
      ],
    );
    return ProviderScope(
      overrides: [hostHomeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  testWidgets('renders header, verification banner, venues, and event cards', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Header
    expect(find.text('Cellar Door Collective'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verification banner
    expect(find.text('Verified. You can publish new events.'), findsOneWidget);

    // Venues card
    expect(find.text('Venues'), findsOneWidget);

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

  testWidgets('tapping event card shows message', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Blind Wine & Bad Takes'));
    await tester.pump();

    expect(find.text('Edit Blind Wine & Bad Takes'), findsOneWidget);
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
}
