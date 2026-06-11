import 'package:draft_race/domain/draft/taunts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tauntFor', () {
    test('returns the custom taunt when non-empty', () {
      expect(
        tauntFor(custom: 'On my back.', seed: 7, pickIndex: 0),
        'On my back.',
      );
    });

    test('trims the custom taunt', () {
      expect(
        tauntFor(custom: '  On my back.  ', seed: 7, pickIndex: 0),
        'On my back.',
      );
    });

    test('falls back to a default for null or blank customs', () {
      for (final custom in [null, '', '   ']) {
        final line = tauntFor(custom: custom, seed: 7, pickIndex: 0);
        expect(kDefaultTaunts, contains(line));
      }
    });

    test('is deterministic for the same seed and pick', () {
      final a = tauntFor(custom: null, seed: 42, pickIndex: 3);
      final b = tauntFor(custom: null, seed: 42, pickIndex: 3);
      expect(a, b);
      expect(a, kDefaultTaunts[(42 + 3) % kDefaultTaunts.length]);
    });

    test('adjacent picks get different default lines', () {
      final first = tauntFor(custom: null, seed: 42, pickIndex: 0);
      final second = tauntFor(custom: null, seed: 42, pickIndex: 1);
      expect(first, isNot(second));
    });

    test('wraps safely past the end of the default list', () {
      final line = tauntFor(
        custom: null,
        seed: 0,
        pickIndex: kDefaultTaunts.length + 2,
      );
      expect(line, kDefaultTaunts[2]);
    });
  });

  test('default taunts are short one-liners', () {
    expect(kDefaultTaunts.length, greaterThanOrEqualTo(10));
    for (final line in kDefaultTaunts) {
      expect(line.trim(), isNotEmpty);
      expect(line.length, lessThanOrEqualTo(60));
      expect(line, isNot(contains('\n')));
    }
  });
}
