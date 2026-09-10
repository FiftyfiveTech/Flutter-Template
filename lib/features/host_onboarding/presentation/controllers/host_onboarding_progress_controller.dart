import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/host_documents_draft.dart';
import '../../domain/entities/host_onboarding_progress.dart';
import '../../domain/entities/host_onboarding_step.dart';
import '../../domain/entities/host_type.dart';
import 'host_onboarding_progress_providers.dart';

part 'host_onboarding_progress_controller.g.dart';

/// Holds the current [HostOnboardingProgress] in memory, backed by
/// `HostOnboardingProgressRepository` so an app restart resumes the
/// wizard on the same step with the same field values instead of
/// restarting it. `keepAlive`, mirroring `HostSessionController`: this
/// outlives any single wizard screen.
@Riverpod(keepAlive: true)
class HostOnboardingProgressController
    extends _$HostOnboardingProgressController {
  @override
  HostOnboardingProgress? build() => null;

  /// Loads the persisted progress, if any. Called once at app bootstrap
  /// (`HostBootstrapPage`), before the initial route is decided.
  Future<void> hydrate() async {
    final result = await ref
        .read(hostOnboardingProgressRepositoryProvider)
        .load();
    result.when(
      ok: (progress) {
        if (progress != null) state = progress;
      },
      err: (_) {},
    );
  }

  void setHostType(HostType type) {
    _update((current) => current.copyWith(hostType: type));
  }

  void updateDocumentsDraft(HostDocumentsDraft draft) {
    _update((current) => current.copyWith(documentsDraft: draft));
  }

  void setStep(HostOnboardingStep step) {
    _update((current) => current.copyWith(step: step));
  }

  void clear() {
    state = null;
    unawaited(ref.read(hostOnboardingProgressRepositoryProvider).clear());
  }

  void _update(
    HostOnboardingProgress Function(HostOnboardingProgress current) apply,
  ) {
    final next = apply(
      state ?? const HostOnboardingProgress(step: HostOnboardingStep.hostType),
    );
    state = next;
    unawaited(ref.read(hostOnboardingProgressRepositoryProvider).save(next));
  }
}
