import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/league_stats.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:flutter_test/flutter_test.dart';

Participant _p(String id, String name, {double weight = 1.0}) => Participant(
  id: id,
  name: name,
  number: '00',
  colorValue: 0xFF000000,
  weight: weight,
);

DraftResult _draft({
  required List<Participant> roster,
  required List<String> order,
  int seed = 1,
  DraftMode mode = DraftMode.race,
  bool weightingEnabled = false,
  bool reverseOrder = false,
  Map<int, String> pins = const {},
  bool withProof = true,
}) {
  final createdAt = DateTime.utc(2026, 6, 1);
  final config = DraftConfig(
    participants: roster,
    mode: mode,
    weightingEnabled: weightingEnabled,
    reverseOrder: reverseOrder,
    pins: pins,
  );
  return DraftResult(
    order: order,
    seed: seed,
    mode: mode,
    createdAt: createdAt,
    rosterSnapshot: roster,
    proofMetadata: withProof
        ? DraftProofMetadata.fromConfig(
            config,
            executedAt: createdAt,
            seed: seed,
          )
        : null,
  );
}

LuckRecord _recordFor(LeagueStats stats, String name) =>
    stats.records.firstWhere((r) => r.name == name);

void main() {
  group('LeagueStats expected pick math', () {
    test('equal weights: expected pick is (n + 1) / 2 for everyone', () {
      // Four managers, no weighting. Expected pick = 2.5 for all, so luck is
      // 2.5 − actual.
      final roster = [_p('a', 'A'), _p('b', 'B'), _p('c', 'C'), _p('d', 'D')];
      final stats = LeagueStats.fromHistory([
        _draft(roster: roster, order: ['a', 'b', 'c', 'd']),
      ]);

      expect(stats.draftCount, 1);
      expect(_recordFor(stats, 'A').totalLuck, closeTo(2.5 - 1, 1e-9));
      expect(_recordFor(stats, 'B').totalLuck, closeTo(2.5 - 2, 1e-9));
      expect(_recordFor(stats, 'C').totalLuck, closeTo(2.5 - 3, 1e-9));
      expect(_recordFor(stats, 'D').totalLuck, closeTo(2.5 - 4, 1e-9));
      // Sorted luckiest first.
      expect([for (final r in stats.records) r.name], ['A', 'B', 'C', 'D']);
      expect(stats.luckiest!.name, 'A');
      expect(stats.unluckiest!.name, 'D');
    });

    test('2x-weight manager in a 3-team league expects pick 5/3', () {
      // Plackett–Luce by hand for weights (2, 1, 1):
      //   P(heavy first)  = 2/4 = 1/2
      //   P(heavy second) = 1/4·(2/3) + 1/4·(2/3) = 1/3
      //   P(heavy third)  = 1 − 1/2 − 1/3 = 1/6
      //   E = 1·(1/2) + 2·(1/3) + 3·(1/6) = 5/3
      // The pairwise identity gives 1 + 1/3 + 1/3 = 5/3 — identical.
      final roster = [_p('h', 'Heavy', weight: 2), _p('x', 'X'), _p('y', 'Y')];
      final stats = LeagueStats.fromHistory([
        _draft(roster: roster, order: ['h', 'x', 'y'], weightingEnabled: true),
      ]);

      // Heavy landed pick 1, so luck = E[pick] − 1 = 5/3 − 1 = 2/3.
      expect(_recordFor(stats, 'Heavy').totalLuck, closeTo(5 / 3 - 1, 1e-9));
      expect(_recordFor(stats, 'Heavy').totalLuck + 1, lessThan(2));
      // The 1x managers each expect 1 + 2/3 + 1/2 = 13/6.
      expect(_recordFor(stats, 'X').totalLuck, closeTo(13 / 6 - 2, 1e-9));
      expect(_recordFor(stats, 'Y').totalLuck, closeTo(13 / 6 - 3, 1e-9));
    });

    test('pairwise identity matches brute-force Plackett–Luce enumeration', () {
      // Enumerate all 6 orderings of 3 managers with weights (3, 2, 1) under
      // the sequential model and compute E[rank] directly; the closed form
      // used by LeagueStats must agree exactly.
      const weights = [3.0, 2.0, 1.0];
      final expectedRank = List<double>.filled(3, 0);
      void walk(List<int> remaining, double prob, List<int> prefix) {
        if (remaining.isEmpty) {
          for (var rank = 0; rank < prefix.length; rank++) {
            expectedRank[prefix[rank]] += prob * (rank + 1);
          }
          return;
        }
        final total = remaining.fold<double>(0, (s, i) => s + weights[i]);
        for (final i in remaining) {
          walk(
            [
              for (final j in remaining)
                if (j != i) j,
            ],
            prob * weights[i] / total,
            [...prefix, i],
          );
        }
      }

      walk([0, 1, 2], 1, []);

      final roster = [
        _p('a', 'A', weight: 3),
        _p('b', 'B', weight: 2),
        _p('c', 'C', weight: 1),
      ];
      final stats = LeagueStats.fromHistory([
        _draft(roster: roster, order: ['a', 'b', 'c'], weightingEnabled: true),
      ]);

      expect(
        _recordFor(stats, 'A').totalLuck,
        closeTo(expectedRank[0] - 1, 1e-9),
      );
      expect(
        _recordFor(stats, 'B').totalLuck,
        closeTo(expectedRank[1] - 2, 1e-9),
      );
      expect(
        _recordFor(stats, 'C').totalLuck,
        closeTo(expectedRank[2] - 3, 1e-9),
      );
    });

    test('reverseOrder flips the expected position', () {
      // With weights (2, 1, 1) and reverse on, the heavy manager expects
      // (3 + 1) − 5/3 = 7/3.
      final roster = [_p('h', 'Heavy', weight: 2), _p('x', 'X'), _p('y', 'Y')];
      final stats = LeagueStats.fromHistory([
        _draft(
          roster: roster,
          order: ['x', 'y', 'h'],
          weightingEnabled: true,
          reverseOrder: true,
        ),
      ]);

      // Heavy landed pick 3, luck = 7/3 − 3 = −2/3.
      expect(_recordFor(stats, 'Heavy').totalLuck, closeTo(7 / 3 - 3, 1e-9));
    });
  });

  group('LeagueStats aggregation', () {
    test('aggregates luck across two drafts', () {
      final roster = [_p('a', 'A'), _p('b', 'B'), _p('c', 'C')];
      final stats = LeagueStats.fromHistory([
        _draft(roster: roster, order: ['a', 'b', 'c'], seed: 1),
        _draft(roster: roster, order: ['b', 'a', 'c'], seed: 2),
      ]);

      expect(stats.draftCount, 2);
      final a = _recordFor(stats, 'A');
      expect(a.drafts, 2);
      // Equal weights, n = 3 → expected 2.0. Picks 1 then 2 → +1.0 + 0.0.
      expect(a.totalLuck, closeTo(1.0, 1e-9));
      expect(a.avgLuck, closeTo(0.5, 1e-9));
      expect(a.bestPick, 1);
      expect(a.worstPick, 2);
      final c = _recordFor(stats, 'C');
      expect(c.totalLuck, closeTo(-2.0, 1e-9));
      expect(c.bestPick, 3);
      expect(c.worstPick, 3);
    });

    test('skips bidding drafts and results without proof metadata', () {
      final roster = [_p('a', 'A'), _p('b', 'B')];
      final stats = LeagueStats.fromHistory([
        _draft(roster: roster, order: ['a', 'b'], mode: DraftMode.bidding),
        _draft(roster: roster, order: ['a', 'b'], withProof: false),
      ]);

      expect(stats.draftCount, 0);
      expect(stats.records, isEmpty);
      expect(stats.luckiest, isNull);
      expect(stats.unluckiest, isNull);
    });

    test('excludes pinned managers from that draft', () {
      final roster = [_p('a', 'A'), _p('b', 'B'), _p('c', 'C')];
      final stats = LeagueStats.fromHistory([
        _draft(roster: roster, order: ['a', 'b', 'c'], pins: const {0: 'a'}),
      ]);

      // A was pinned to pick #1: no luck involved, no record.
      expect(stats.records.map((r) => r.name), isNot(contains('A')));
      // B and C form a pool of 2 (expected 1.5 within the pool).
      expect(_recordFor(stats, 'B').totalLuck, closeTo(0.5, 1e-9));
      expect(_recordFor(stats, 'C').totalLuck, closeTo(-0.5, 1e-9));
    });

    test('merges records by case-insensitive name when ids differ', () {
      final season1 = [_p('s1-nick', 'Nick'), _p('s1-jo', 'Jordan')];
      final season2 = [_p('s2-nick', 'NICK'), _p('s2-jo', 'Jordan')];
      final stats = LeagueStats.fromHistory([
        _draft(roster: season1, order: ['s1-nick', 's1-jo'], seed: 1),
        _draft(roster: season2, order: ['s2-nick', 's2-jo'], seed: 2),
      ]);

      expect(stats.records, hasLength(2));
      final nick = _recordFor(stats, 'Nick');
      expect(nick.drafts, 2);
      // Pool of 2, expected 1.5, pick 1 both times → +0.5 + 0.5.
      expect(nick.totalLuck, closeTo(1.0, 1e-9));
    });
  });
}
