import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_type.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/usecases/validate_host_type_selection.dart';

void main() {
  const useCase = ValidateHostTypeSelectionUseCase();

  test('returns Ok with the selected host type', () {
    final result = useCase(HostType.venue);

    expect(result, isA<Ok<HostType>>());
    result.when(
      ok: (type) => expect(type, HostType.venue),
      err: (_) => fail('expected Ok'),
    );
  });

  test('flags a missing selection', () {
    final result = useCase(null);

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) => expect(failure.message, isNotEmpty),
    );
  });
}
