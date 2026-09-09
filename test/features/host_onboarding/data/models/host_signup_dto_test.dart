import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_onboarding/data/models/host_signup_dto.dart';
import 'package:host_mobile_app/features/host_onboarding/domain/entities/host_signup_draft.dart';

void main() {
  group('HostSignupRequestDto.fromDraft', () {
    test('leaves an already-E.164 phone number untouched', () {
      const draft = HostSignupDraft(
        businessName: 'Cellar Door Collective',
        contactPhone: '+919876543210',
        contactEmail: 'you@business.com',
        city: 'Chennai city',
        cityId: 'city-1',
      );

      final dto = HostSignupRequestDto.fromDraft(draft);

      expect(dto.phoneNumber, '+919876543210');
    });

    test('prefixes a bare 10-digit phone number with the +91 country code', () {
      const draft = HostSignupDraft(
        businessName: 'Cellar Door Collective',
        contactPhone: '9876543210',
        contactEmail: 'you@business.com',
        city: 'Chennai city',
        cityId: 'city-1',
      );

      final dto = HostSignupRequestDto.fromDraft(draft);

      expect(dto.phoneNumber, '+919876543210');
    });

    test('toJson sends the normalized phone number under phoneNumber', () {
      const draft = HostSignupDraft(
        businessName: 'Cellar Door Collective',
        contactPhone: '9876543210',
        contactEmail: 'you@business.com',
        city: 'Chennai city',
        cityId: 'city-1',
      );

      final json = HostSignupRequestDto.fromDraft(draft).toJson();

      expect(json, {
        'businessName': 'Cellar Door Collective',
        'phoneNumber': '+919876543210',
        'contactEmail': 'you@business.com',
        'cityId': 'city-1',
      });
    });
  });
}
