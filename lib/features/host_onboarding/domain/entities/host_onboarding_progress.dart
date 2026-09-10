import 'host_documents_draft.dart';
import 'host_onboarding_step.dart';
import 'host_type.dart';

/// The persisted snapshot of where a host is in the onboarding wizard —
/// current step plus every field filled in so far, so
/// `HostBootstrapPage` can resume the exact screen and form state after
/// a restart.
class HostOnboardingProgress {
  const HostOnboardingProgress({
    required this.step,
    this.hostType,
    this.documentsDraft = const HostDocumentsDraft(),
  });

  final HostOnboardingStep step;
  final HostType? hostType;
  final HostDocumentsDraft documentsDraft;

  HostOnboardingProgress copyWith({
    HostOnboardingStep? step,
    HostType? hostType,
    HostDocumentsDraft? documentsDraft,
  }) {
    return HostOnboardingProgress(
      step: step ?? this.step,
      hostType: hostType ?? this.hostType,
      documentsDraft: documentsDraft ?? this.documentsDraft,
    );
  }
}
