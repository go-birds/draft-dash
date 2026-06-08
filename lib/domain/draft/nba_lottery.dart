import 'dart:math';

import 'draft_config.dart';
import 'participant.dart';

/// NBA-style lottery using 14 balls and 4-number combinations.
///
/// There are 1,001 possible 4-ball combinations from balls 1..14. The classic
/// NBA process ignores 11-12-13-14, leaving 1,000 assigned combinations.
class NbaLottery {
  static const int ballCount = 14;
  static const int ballsPerDraw = 4;
  static const int assignedCombinationCount = 1000;
  static const List<int> ignoredCombination = [11, 12, 13, 14];
  static const double _minWeight = 1e-4;

  const NbaLottery._();

  static NbaLotteryPlan generate(DraftConfig config, {required int seed}) {
    final participants = config.participants;
    final assignment = NbaLotteryAssignment.fromParticipants(
      participants,
      weightingEnabled: config.weightingEnabled,
    );
    final rng = Random(seed);
    final rounds = <NbaLotteryRound>[];
    final won = <String>{};
    final topPickCount = config.effectiveLotteryPickCount;

    for (var pickIndex = 0; pickIndex < topPickCount; pickIndex++) {
      while (true) {
        final balls = _drawCombination(rng);
        final owner = assignment.ownerOf(balls);
        if (owner == null || won.contains(owner)) {
          continue;
        }
        won.add(owner);
        rounds.add(
          NbaLotteryRound(pickIndex: pickIndex, balls: balls, winnerId: owner),
        );
        break;
      }
    }

    final remaining = _weightedRanking(
      participants.where((p) => !won.contains(p.id)).toList(),
      Random(seed ^ 0x5EEDBEEF),
      weightingEnabled: config.weightingEnabled,
    );

    return NbaLotteryPlan(
      assignment: assignment,
      rounds: rounds,
      order: [for (final round in rounds) round.winnerId, ...remaining],
    );
  }

  static List<int> _drawCombination(Random rng) {
    final pool = [for (var i = 1; i <= ballCount; i++) i];
    final drawn = <int>[];
    for (var i = 0; i < ballsPerDraw; i++) {
      drawn.add(pool.removeAt(rng.nextInt(pool.length)));
    }
    drawn.sort();
    return drawn;
  }

  static List<String> _weightedRanking(
    List<Participant> participants,
    Random rng, {
    required bool weightingEnabled,
  }) {
    final keyed = <(String, double)>[];
    for (final p in participants) {
      final w = weightingEnabled ? max(p.weight, _minWeight) : 1.0;
      final u = 1.0 - rng.nextDouble();
      keyed.add((p.id, pow(u, 1.0 / w).toDouble()));
    }
    keyed.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final e in keyed) e.$1];
  }
}

class NbaLotteryPlan {
  final NbaLotteryAssignment assignment;
  final List<NbaLotteryRound> rounds;
  final List<String> order;

  const NbaLotteryPlan({
    required this.assignment,
    required this.rounds,
    required this.order,
  });
}

class NbaLotteryRound {
  final int pickIndex;
  final List<int> balls;
  final String winnerId;

  const NbaLotteryRound({
    required this.pickIndex,
    required this.balls,
    required this.winnerId,
  });
}

class NbaLotteryAssignment {
  final Map<String, int> combinationCounts;
  final Map<String, int> totalCombinationCounts;
  final Map<String, List<List<int>>> combinationsByOwner;
  final Map<String, String> ownersByCombinationKey;
  final List<List<int>> assignedCombinations;

  const NbaLotteryAssignment({
    required this.combinationCounts,
    required this.totalCombinationCounts,
    required this.combinationsByOwner,
    required this.ownersByCombinationKey,
    required this.assignedCombinations,
  });

  factory NbaLotteryAssignment.fromParticipants(
    List<Participant> participants, {
    required bool weightingEnabled,
  }) {
    final combos = _allAssignedCombinations();
    final counts = _comboCounts(participants, weightingEnabled);
    final byOwner = {for (final p in participants) p.id: <List<int>>[]};
    final ownersByKey = <String, String>{};

    var cursor = 0;
    for (final p in participants) {
      final count = counts[p.id] ?? 0;
      for (var i = 0; i < count && cursor < combos.length; i++) {
        final combo = combos[cursor++];
        byOwner[p.id]!.add(combo);
        ownersByKey[_key(combo)] = p.id;
      }
    }

    return NbaLotteryAssignment(
      combinationCounts: counts,
      totalCombinationCounts: counts,
      combinationsByOwner: byOwner,
      ownersByCombinationKey: ownersByKey,
      assignedCombinations: combos,
    );
  }

  String? ownerOf(List<int> balls) => ownersByCombinationKey[_key(balls)];

  Map<String, double> chancesAfter({
    required List<int> drawnBalls,
    Set<String> alreadyWon = const {},
  }) {
    final drawn = [...drawnBalls]..sort();
    final counts = {for (final id in combinationCounts.keys) id: 0};
    var total = 0;

    for (final e in ownersByCombinationKey.entries) {
      final owner = e.value;
      if (alreadyWon.contains(owner)) continue;
      final combo = _parseKey(e.key);
      if (!_containsPrefix(combo, drawn)) continue;
      counts[owner] = (counts[owner] ?? 0) + 1;
      total++;
    }

    if (total == 0) {
      return {for (final id in counts.keys) id: 0};
    }
    return {for (final e in counts.entries) e.key: e.value / total};
  }

  static bool _containsPrefix(List<int> combo, List<int> drawn) {
    for (final ball in drawn) {
      if (!combo.contains(ball)) return false;
    }
    return true;
  }

  static List<List<int>> _allAssignedCombinations() {
    final combos = <List<int>>[];
    for (var a = 1; a <= NbaLottery.ballCount - 3; a++) {
      for (var b = a + 1; b <= NbaLottery.ballCount - 2; b++) {
        for (var c = b + 1; c <= NbaLottery.ballCount - 1; c++) {
          for (var d = c + 1; d <= NbaLottery.ballCount; d++) {
            final combo = [a, b, c, d];
            if (_key(combo) != _key(NbaLottery.ignoredCombination)) {
              combos.add(combo);
            }
          }
        }
      }
    }
    return combos;
  }

  static Map<String, int> _comboCounts(
    List<Participant> participants,
    bool weightingEnabled,
  ) {
    if (participants.isEmpty) return const {};
    final weights = {
      for (final p in participants)
        p.id: weightingEnabled ? max(p.weight, NbaLottery._minWeight) : 1.0,
    };
    final totalWeight = weights.values.fold<double>(0, (a, b) => a + b);
    final raw = {
      for (final p in participants)
        p.id:
            (weights[p.id]! / totalWeight) *
            NbaLottery.assignedCombinationCount,
    };
    final counts = {for (final e in raw.entries) e.key: e.value.floor()};
    var assigned = counts.values.fold<int>(0, (a, b) => a + b);
    final remainders = raw.entries.toList()
      ..sort((a, b) {
        final r = (b.value - b.value.floor()).compareTo(
          a.value - a.value.floor(),
        );
        return r != 0 ? r : a.key.compareTo(b.key);
      });
    var i = 0;
    while (assigned < NbaLottery.assignedCombinationCount) {
      counts[remainders[i % remainders.length].key] =
          counts[remainders[i % remainders.length].key]! + 1;
      assigned++;
      i++;
    }
    return counts;
  }

  static String _key(List<int> combo) {
    final sorted = [...combo]..sort();
    return sorted.join('-');
  }

  static List<int> _parseKey(String key) =>
      key.split('-').map(int.parse).toList();
}
