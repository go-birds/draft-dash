import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_engine.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:flutter_test/flutter_test.dart';

List<Participant> roster(int n, {List<double>? weights}) => [
      for (var i = 0; i < n; i++)
        Participant(
          id: 'p$i',
          name: 'P$i',
          number: '${i + 1}',
          colorValue: 0xFF000000 | i,
          weight: weights == null ? 1.0 : weights[i],
        ),
    ];

void main() {
  group('DraftEngine.generate', () {
    test('produces a valid permutation (no dupes, no omissions)', () {
      final cfg = DraftConfig(participants: roster(12));
      final r = DraftEngine.generate(cfg, seed: 7);
      expect(r.order.length, 12);
      expect(r.order.toSet().length, 12);
      expect(r.order.toSet(), {for (final p in cfg.participants) p.id});
    });

    test('is deterministic for a given seed', () {
      final cfg = DraftConfig(participants: roster(10));
      final a = DraftEngine.generate(cfg, seed: 42);
      final b = DraftEngine.generate(cfg, seed: 42);
      expect(a.order, b.order);
    });

    test('different seeds generally produce different orders', () {
      final cfg = DraftConfig(participants: roster(10));
      final a = DraftEngine.generate(cfg, seed: 1);
      final b = DraftEngine.generate(cfg, seed: 2);
      expect(a.order == b.order, isFalse);
    });

    test('pins land at their exact pick slots', () {
      final cfg = DraftConfig(
        participants: roster(8),
        pins: {0: 'p5', 3: 'p1'},
      );
      for (var seed = 0; seed < 50; seed++) {
        final r = DraftEngine.generate(cfg, seed: seed);
        expect(r.order[0], 'p5');
        expect(r.order[3], 'p1');
        expect(r.order.toSet().length, 8); // still valid
      }
    });

    test('all-pinned config reproduces the pins exactly', () {
      final pins = {for (var i = 0; i < 5; i++) i: 'p${4 - i}'};
      final cfg = DraftConfig(participants: roster(5), pins: pins);
      final r = DraftEngine.generate(cfg, seed: 99);
      expect(r.order, ['p4', 'p3', 'p2', 'p1', 'p0']);
    });

    test('weighting biases the heavy manager toward pick #1', () {
      // p0 is 9x as likely as everyone else.
      final cfg = DraftConfig(
        participants: roster(5, weights: [9, 1, 1, 1, 1]),
      );
      var firsts = 0;
      const trials = 4000;
      for (var s = 0; s < trials; s++) {
        if (DraftEngine.generate(cfg, seed: s).order.first == 'p0') firsts++;
      }
      final share = firsts / trials;
      // Expected ~ 9/13 ≈ 0.69; assert clearly above the even share (0.2).
      expect(share, greaterThan(0.55));
    });

    test('weightingEnabled=false ignores weights (≈ uniform)', () {
      final cfg = DraftConfig(
        participants: roster(5, weights: [9, 1, 1, 1, 1]),
        weightingEnabled: false,
      );
      var firsts = 0;
      const trials = 4000;
      for (var s = 0; s < trials; s++) {
        if (DraftEngine.generate(cfg, seed: s).order.first == 'p0') firsts++;
      }
      final share = firsts / trials;
      expect(share, closeTo(0.2, 0.06));
    });

    test('reverseOrder sends the favored manager toward the last pick', () {
      final cfg = DraftConfig(
        participants: roster(6, weights: [50, 1, 1, 1, 1, 1]),
        reverseOrder: true,
      );
      var lasts = 0;
      const trials = 2000;
      for (var s = 0; s < trials; s++) {
        if (DraftEngine.generate(cfg, seed: s).order.last == 'p0') lasts++;
      }
      expect(lasts / trials, greaterThan(0.6));
    });

    test('relativeOdds normalizes weights to sum ~1', () {
      final cfg = DraftConfig(participants: roster(4, weights: [3, 1, 1, 1]));
      final odds = DraftEngine.relativeOdds(cfg);
      final total = odds.values.fold<double>(0, (a, b) => a + b);
      expect(total, closeTo(1.0, 1e-9));
      expect(odds['p0'], closeTo(0.5, 1e-9));
    });

    test('relativeOdds: pin on pick #1 gives certainty', () {
      final cfg = DraftConfig(participants: roster(4), pins: {0: 'p2'});
      final odds = DraftEngine.relativeOdds(cfg);
      expect(odds['p2'], 1.0);
      expect(odds['p0'], 0.0);
    });
  });
}
