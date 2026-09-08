import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/host_type.dart';

/// Validates the H-02 host type step: a selection is required before the
/// wizard can advance, since it decides H-03's document set.
class ValidateHostTypeSelectionUseCase {
  const ValidateHostTypeSelectionUseCase();

  Result<HostType> call(HostType? selected) {
    if (selected == null) {
      return const Err(
        ValidationFailure(message: 'Choose a host type to continue'),
      );
    }
    return Ok(selected);
  }
}
