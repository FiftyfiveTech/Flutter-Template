import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/host_type.dart';
import '../../domain/usecases/validate_host_type_selection.dart';

part 'host_type_controller.g.dart';

/// Holds the H-02 host type selection. Screen-scoped (autoDispose): the
/// selection only needs to live for the duration of this step.
@riverpod
class HostTypeController extends _$HostTypeController {
  static const _useCase = ValidateHostTypeSelectionUseCase();

  @override
  HostType? build() => null;

  void selectHostType(HostType type) {
    state = type;
  }

  /// Validates the selection. Callers branch on the result to either show
  /// the "choose one" message or advance to H-03 · Documents.
  Result<HostType> submit() => _useCase(state);
}
