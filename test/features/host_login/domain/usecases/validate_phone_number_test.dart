import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_login/domain/usecases/validate_phone_number.dart';

void main() {
  const useCase = ValidatePhoneNumberUseCase();

  test('returns Ok with a bare 10-digit number unchanged', () {
    final result = useCase('9876543210');

    expect(result, isA<Ok<String>>());
    result.when(
      ok: (phone) => expect(phone, '9876543210'),
      err: (_) => fail('expected Ok'),
    );
  });

  test('accepts a +91-prefixed number', () {
    final result = useCase('+919876543210');

    expect(result, isA<Ok<String>>());
  });

  test('flags a number that does not start 6-9', () {
    final result = useCase('5876543210');

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        expect(failure, isA<PhoneValidationFailure>());
        expect(
          (failure as PhoneValidationFailure).fieldErrors,
          containsPair('phoneNumber', isNotEmpty),
        );
      },
    );
  });

  test('flags a number with the wrong digit count', () {
    final result = useCase('987654321');

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        expect(failure, isA<PhoneValidationFailure>());
      },
    );
  });
}
