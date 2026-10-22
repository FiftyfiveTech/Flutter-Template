import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:host_mobile_app/core/di/database_providers.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile.dart';
import 'package:host_mobile_app/features/host_profile/domain/entities/host_profile_edit.dart';
import 'package:host_mobile_app/features/host_profile/domain/repositories/host_profile_repository.dart';
import 'package:host_mobile_app/features/host_profile/domain/usecases/update_host_profile.dart';
import 'package:host_mobile_app/features/host_profile/presentation/controllers/host_profile_providers.dart';
import 'package:host_mobile_app/features/host_profile/presentation/pages/host_edit_profile_page.dart';
import 'package:host_mobile_app/shared/widgets/ah_button.dart';

import '../../../support/fakes.dart';

class _FakeRepository implements HostProfileRepository {
  _FakeRepository({this.cached});

  final HostProfile? cached;
  Failure? updateFailure;
  final edits = <HostProfileEdit>[];
  var fetchCalls = 0;

  @override
  Future<Result<HostProfile>> fetch(String userId) async {
    fetchCalls++;
    return Ok(cached ?? HostProfile(userId: userId));
  }

  @override
  Future<Result<HostProfile?>> getCached(String userId) async => Ok(cached);

  @override
  Future<Result<HostProfile>> update(
    String userId,
    HostProfileEdit edit,
  ) async {
    edits.add(edit);
    if (updateFailure != null) return Err(updateFailure!);
    return Ok(HostProfile(userId: userId, hostName: edit.businessName ?? ''));
  }

  @override
  Future<Result<void>> cache(HostProfile profile) async => const Ok(null);

  @override
  Future<Result<void>> clear() async => const Ok(null);

  @override
  Future<Result<void>> deleteAccount() async => const Ok(null);
}

void main() {
  late _FakeRepository repository;

  setUp(() {
    repository = _FakeRepository(
      cached: const HostProfile(
        userId: 'u1',
        hostName: 'Cellar Door',
        firstName: 'Aarav',
        lastName: 'Shetty',
      ),
    );
  });

  Widget buildSubject() {
    final router = GoRouter(
      initialLocation: '/you/edit',
      routes: [
        GoRoute(
          path: '/you',
          builder: (context, state) => const Scaffold(body: Text('You page')),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const HostEditProfilePage(),
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        hostProfileRepositoryProvider.overrideWithValue(repository),
        hostSessionLocalDatasourceProvider.overrideWithValue(
          FakeHostSessionLocalDatasource(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  // Fields in page order: first name, last name, business name.
  Finder field(String label) => find
      .byType(TextField)
      .at(
        const [
          'First name',
          'Last name',
          'Business or organiser name',
        ].indexOf(label),
      );

  testWidgets('prefills the form from the cached profile', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Aarav'), findsOneWidget);
    expect(find.text('Shetty'), findsOneWidget);
    expect(find.text('Cellar Door'), findsOneWidget);
  });

  testWidgets('saving with no changes closes without calling the API', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AhButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.edits, isEmpty);
    expect(find.text('You page'), findsOneWidget);
  });

  testWidgets('sends only the changed field and closes on success', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(field('Last name'), 'Rao');
    await tester.tap(find.widgetWithText(AhButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.edits.single.lastName, 'Rao');
    expect(repository.edits.single.firstName, isNull);
    expect(repository.edits.single.businessName, isNull);
    // A successful edit re-fetches the profile once.
    expect(repository.fetchCalls, 1);
    expect(find.text('You page'), findsOneWidget);
  });

  testWidgets('a blank edited field shows an inline error and stays open', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(field('First name'), ' ');
    await tester.tap(find.widgetWithText(AhButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a first name'), findsOneWidget);
    expect(repository.edits, isEmpty);
    expect(repository.fetchCalls, 0);
    expect(find.text('You page'), findsNothing);
  });

  testWidgets('shows a server field error under its input', (tester) async {
    repository.updateFailure = const HostProfileValidationFailure({
      'businessName': 'businessName is taken',
    });
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(field('Business or organiser name'), 'Other');
    await tester.tap(find.widgetWithText(AhButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('businessName is taken'), findsOneWidget);
    expect(find.text('You page'), findsNothing);
  });

  testWidgets('shows a message sheet when the save fails', (tester) async {
    repository.updateFailure = const NetworkFailure();
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(field('Last name'), 'Rao');
    await tester.tap(find.widgetWithText(AhButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('You page'), findsNothing);
  });
}
