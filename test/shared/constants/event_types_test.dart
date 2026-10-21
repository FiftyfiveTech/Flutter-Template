import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/shared/constants/event_types.dart';

void main() {
  group('filterEventTypes', () {
    test('an empty query returns every option', () {
      expect(filterEventTypes(kEventTypeOptions, ''), kEventTypeOptions);
    });

    test('matches case-insensitively anywhere in the label', () {
      expect(filterEventTypes(kEventTypeOptions, 'GAM'), ['Board games']);
      expect(filterEventTypes(kEventTypeOptions, ' up '), ['Stand up']);
    });

    test('leaves out excluded (already picked) options', () {
      expect(filterEventTypes(kEventTypeOptions, 'd', exclude: ['Dinner']), [
        'Board games',
        'Dance',
        'Stand up',
      ]);
    });
  });
}
