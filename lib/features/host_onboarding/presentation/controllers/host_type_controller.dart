import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/host_type.dart';
import '../../domain/usecases/validate_host_type_selection.dart';
import 'host_onboarding_progress_controller.dart';

part 'host_type_controller.g.dart';

/// Holds the H-02 host type selection. Screen-scoped (autoDispose): the
/// selection only needs to live for the duration of this step — the
/// persisted copy lives in `HostOnboardingProgressController` instead,
/// which is what [build] seeds from so a restart resumes the pick.
@riverpod
class HostTypeController extends _$HostTypeController {
  static const _useCase = ValidateHostTypeSelectionUseCase();

  @override
  HostType? build() =>
      ref.read(hostOnboardingProgressControllerProvider)?.hostType;

  void selectHostType(HostType type) {
    state = type;
    ref
        .read(hostOnboardingProgressControllerProvider.notifier)
        .setHostType(type);
  }

  /// Validates the selection. Callers branch on the result to either show
  /// the "choose one" message or advance to H-03 · Documents.
  Result<HostType> submit() => _useCase(state);
}
