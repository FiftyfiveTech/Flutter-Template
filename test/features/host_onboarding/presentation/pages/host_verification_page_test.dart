import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:host_mobile_app/core/error/failures.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_status.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_type.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_document_verification_status.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/repositories/host_document_status_repository.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_document_status_api_providers.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/pages/host_verification_page.dart';

class _FakeHostDocumentStatusRepository
    implements HostDocumentStatusRepository {
  _FakeHostDocumentStatusRepository(this._results);
  final List<Result<List<HostDocumentStatus>>> _results;
  int _calls = 0;

  @override
  Future<Result<List<HostDocumentStatus>>> getDocumentsStatus() async {
    final result = _results[_calls.clamp(0, _results.length - 1)];
    _calls++;
    return result;
  }
}

void main() {
  Widget buildSubject(List<Result<List<HostDocumentStatus>>> results) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HostVerificationPage(),
        ),
        GoRoute(
          path: '/host/home',
          builder: (context, state) => const Scaffold(body: Text('Home page')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        hostDocumentStatusRepositoryProvider.overrideWithValue(
          _FakeHostDocumentStatusRepository(results),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  testWidgets('the system back gesture cannot return to H-03 · Documents', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/verification'),
              child: const Text('Go to verification'),
            ),
          ),
        ),
        GoRoute(
          path: '/verification',
          builder: (context, state) => const HostVerificationPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hostDocumentStatusRepositoryProvider.overrideWithValue(
            _FakeHostDocumentStatusRepository([
              const Ok([
                HostDocumentStatus(
                  docType: HostDocumentType.panCard,
                  status: HostDocumentVerificationStatus.pending,
                ),
              ]),
            ]),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );

    await tester.tap(find.text('Go to verification'));
    await tester.pumpAndSettle();
    expect(find.text('Verification'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('Go to verification'), findsNothing);
  });

  testWidgets(
    'shows the under-review state and no home button when a document is '
    'still pending',
    (tester) async {
      await tester.pumpWidget(
        buildSubject([
          const Ok([
            HostDocumentStatus(
              docType: HostDocumentType.panCard,
              status: HostDocumentVerificationStatus.verified,
            ),
            HostDocumentStatus(
              docType: HostDocumentType.businessRegistration,
              status: HostDocumentVerificationStatus.pending,
            ),
          ]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Go to home'), findsNothing);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the verified state and a home button once every document is '
    'verified',
    (tester) async {
      await tester.pumpWidget(
        buildSubject([
          const Ok([
            HostDocumentStatus(
              docType: HostDocumentType.panCard,
              status: HostDocumentVerificationStatus.verified,
            ),
          ]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsNWidgets(2));
      expect(find.text('Go to home'), findsOneWidget);

      await tester.tap(find.text('Go to home'));
      await tester.pumpAndSettle();

      expect(find.text('Home page'), findsOneWidget);
    },
  );

  testWidgets('shows a retry banner when the status fetch fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject([const Err(NetworkFailure(message: 'Request failed.'))]),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Couldn't load your verification status"),
      findsOneWidget,
    );
  });

  testWidgets('pull-to-refresh re-fetches the status', (tester) async {
    await tester.pumpWidget(
      buildSubject([
        const Ok([
          HostDocumentStatus(
            docType: HostDocumentType.panCard,
            status: HostDocumentVerificationStatus.pending,
          ),
        ]),
        const Ok([
          HostDocumentStatus(
            docType: HostDocumentType.panCard,
            status: HostDocumentVerificationStatus.verified,
          ),
        ]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Under review'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Verified'), findsNWidgets(2));
  });
}
