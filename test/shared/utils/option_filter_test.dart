import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/shared/utils/option_filter.dart';

const _options = ['Dinner', 'Board games', 'Dance', 'Stand up'];

void main() {
  group('filterOptions', () {
    test('an empty query returns every option', () {
      expect(filterOptions(_options, ''), _options);
    });

    test('matches case-insensitively anywhere in the label', () {
      expect(filterOptions(_options, 'GAM'), ['Board games']);
      expect(filterOptions(_options, ' up '), ['Stand up']);
    });

    test('leaves out excluded (already picked) options', () {
      expect(filterOptions(_options, 'd', exclude: ['Dinner']), [
        'Board games',
        'Dance',
        'Stand up',
      ]);
    });
  });

  group('optionToApi / optionFromApi', () {
    test('sends the lowercased label', () {
      expect(optionToApi('Board games'), 'board games');
    });

    test('maps a backend value back to its label', () {
      expect(optionFromApi(_options, 'stand up'), 'Stand up');
    });

    test('reads older underscored values', () {
      expect(optionFromApi(_options, 'board_games'), 'Board games');
    });

    test('keeps an unknown value as-is', () {
      expect(optionFromApi(_options, 'workshop'), 'workshop');
    });
  });
}
