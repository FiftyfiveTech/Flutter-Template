import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_signup_draft.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/usecases/validate_host_signup_basics.dart';

void main() {
  const useCase = ValidateHostSignupBasicsUseCase();

  const validDraft = HostSignupDraft(
    businessName: 'Cellar Door Collective',
    contactPhone: '+919876543210',
    contactEmail: 'you@business.com',
    city: 'Bangalore',
    cityId: 'city-1',
  );

  test('returns Ok with a trimmed draft when all fields are valid', () {
    final result = useCase(
      validDraft.copyWith(businessName: '  Cellar Door Collective  '),
    );

    expect(result, isA<Ok<HostSignupDraft>>());
    result.when(
      ok: (draft) => expect(draft.businessName, 'Cellar Door Collective'),
      err: (_) => fail('expected Ok'),
    );
  });

  test('flags an empty business name', () {
    final result = useCase(validDraft.copyWith(businessName: '  '));

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        expect(failure, isA<HostSignupValidationFailure>());
        expect(
          (failure as HostSignupValidationFailure).fieldErrors,
          containsPair('businessName', isNotEmpty),
        );
      },
    );
  });

  test('flags an invalid phone number', () {
    final result = useCase(validDraft.copyWith(contactPhone: '12345'));

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostSignupValidationFailure).fieldErrors;
        expect(fieldErrors, containsPair('contactPhone', isNotEmpty));
      },
    );
  });

  test('flags a 10-digit phone number that does not start 6-9', () {
    final result = useCase(validDraft.copyWith(contactPhone: '5876543210'));

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostSignupValidationFailure).fieldErrors;
        expect(fieldErrors, containsPair('contactPhone', isNotEmpty));
      },
    );
  });

  test('flags an invalid email address', () {
    final result = useCase(validDraft.copyWith(contactEmail: 'not-an-email'));

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostSignupValidationFailure).fieldErrors;
        expect(fieldErrors, containsPair('contactEmail', isNotEmpty));
      },
    );
  });

  test('flags a missing city', () {
    final result = useCase(validDraft.copyWith(city: ''));

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostSignupValidationFailure).fieldErrors;
        expect(fieldErrors, containsPair('city', isNotEmpty));
      },
    );
  });

  test('flags a city name with no backing city id', () {
    final result = useCase(validDraft.copyWith(cityId: ''));

    result.when(
      ok: (_) => fail('expected Err'),
      err: (failure) {
        final fieldErrors =
            (failure as HostSignupValidationFailure).fieldErrors;
        expect(fieldErrors, containsPair('city', isNotEmpty));
      },
    );
  });
}
