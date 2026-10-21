import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/di/database_providers.dart';
import 'package:host_mobile_app/core/di/session_providers.dart';
import 'package:host_mobile_app/core/session/host_session.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_documents_draft.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_onboarding_progress.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_onboarding_step.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_type.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_onboarding_progress_controller.dart';
import 'package:host_mobile_app/features/host_onboarding/presentation/controllers/host_onboarding_progress_providers.dart';

import '../../../../support/fakes.dart';

const _session = HostSession(
  accessToken: 't',
  userId: 'u1',
  accountStatus: 'active',
);

/// A previous host's half-finished wizard, as left on the device.
const _previousHostProgress = HostOnboardingProgress(
  step: HostOnboardingStep.verification,
  hostType: HostType.venue,
  documentsDraft: HostDocumentsDraft(upiId: 'old@upi', servesAlcohol: true),
);

void main() {
  late FakeHostOnboardingProgressRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeHostOnboardingProgressRepository(
      initial: _previousHostProgress,
    );
    container = ProviderContainer(
      overrides: [
        hostOnboardingProgressRepositoryProvider.overrideWithValue(repository),
        hostSessionLocalDatasourceProvider.overrideWithValue(
          FakeHostSessionLocalDatasource(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<HostOnboardingProgress?> persisted() async =>
      (await repository.load()).when(ok: (p) => p, err: (_) => null);

  test('ending the session wipes saved and in-memory progress', () async {
    container.read(hostSessionControllerProvider.notifier).setSession(_session);
    await container
        .read(hostOnboardingProgressControllerProvider.notifier)
        .hydrate();
    expect(container.read(hostOnboardingProgressControllerProvider), isNotNull);

    container.read(hostSessionControllerProvider.notifier).clear();
    await pumpEventQueue();

    expect(container.read(hostOnboardingProgressControllerProvider), isNull);
    expect(await persisted(), isNull);
  });

  test('an expired session also wipes progress', () async {
    container.read(hostSessionControllerProvider.notifier).setSession(_session);
    await container
        .read(hostOnboardingProgressControllerProvider.notifier)
        .hydrate();

    container.read(hostSessionControllerProvider.notifier).expire();
    await pumpEventQueue();

    expect(await persisted(), isNull);
  });

  test('restart discards an earlier host\'s type and documents', () async {
    final notifier = container.read(
      hostOnboardingProgressControllerProvider.notifier,
    );
    await notifier.hydrate();

    notifier.restart(HostOnboardingStep.hostType);
    await pumpEventQueue();

    final progress = container.read(hostOnboardingProgressControllerProvider);
    expect(progress?.step, HostOnboardingStep.hostType);
    expect(progress?.hostType, isNull);
    expect(progress?.documentsDraft.upiId, isEmpty);
    expect(progress?.documentsDraft.servesAlcohol, isFalse);
    expect((await persisted())?.hostType, isNull);
  });
}
