import 'dart:math';

import 'draft_config.dart';
import 'draft_mode.dart';
import 'draft_result.dart';
import 'participant.dart';

/// The heart of the app. Pure, deterministic given a seed.
///
/// Produces the final pick order for the auto-reveal modes, honoring:
///  - weighted odds (Efraimidis–Spirakis weighted sampling without replacement),
///  - commissioner pins (exact pick positions fixed before the draw),
///  - reverse ordering (top performer gets the last pick instead of the first).
///
/// Every presentation (race/cards/lottery) simply dramatizes this result, so
/// odds and cheating behave identically across all of them.
class DraftEngine {
  static const double _minWeight = 1e-4;

  static DraftResult generate(DraftConfig config, {required int seed}) {
    final n = config.size;
    final rng = Random(seed);

    // 1. Weighted permutation of ALL managers, best performer first.
    //    key_i = u^(1/w_i); larger key sorts earlier.
    final ranked = _weightedRanking(config, rng);

    // 2. baseOrder: pick order ignoring pins (reverse flips first<->last).
    final baseOrder = config.reverseOrder ? ranked.reversed.toList() : ranked;

    // 3. Place pins at their exact pick slots; fill the rest from baseOrder.
    final result = List<String?>.filled(n, null);
    final pinnedIds = <String>{};
    final validIds = {for (final p in config.participants) p.id};
    config.pins.forEach((slot, id) {
      if (slot >= 0 &&
          slot < n &&
          validIds.contains(id) &&
          !pinnedIds.contains(id)) {
        result[slot] = id;
        pinnedIds.add(id);
      }
    });

    var feed = 0;
    final flow = [
      for (final id in baseOrder)
        if (!pinnedIds.contains(id)) id,
    ];
    for (var i = 0; i < n; i++) {
      if (result[i] == null) {
        result[i] = flow[feed++];
      }
    }

    final order = [for (final id in result) id!];
    assert(
      _isPermutation(order, config),
      'DraftEngine produced an invalid ordering',
    );

    return DraftResult(
      order: order,
      seed: seed,
      mode: config.mode,
      createdAt: DateTime.now(),
      rosterSnapshot: List<Participant>.unmodifiable(config.participants),
    );
  }

  /// Weighted-random ordering of all participant ids, best (earliest) first.
  static List<String> _weightedRanking(DraftConfig config, Random rng) {
    final keyed = <(String, double)>[];
    for (final p in config.participants) {
      final w = config.weightingEnabled ? max(p.weight, _minWeight) : 1.0;
      // u in (0,1]; avoid 0 so pow is well-defined.
      final u = 1.0 - rng.nextDouble();
      final key = pow(u, 1.0 / w).toDouble();
      keyed.add((p.id, key));
    }
    keyed.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final e in keyed) e.$1];
  }

  /// Relative chance (0..1) each manager lands pick #1, for display in the UI.
  /// Honors weighting and a pin on pick #1; pinned-elsewhere managers are
  /// excluded from the pick-#1 pool.
  static Map<String, double> relativeOdds(DraftConfig config) {
    final ids = [for (final p in config.participants) p.id];
    final result = {for (final id in ids) id: 0.0};
    if (ids.isEmpty) return result;

    // Pick #1 pinned → certainty.
    final pinnedFirst = config.pins[0];
    if (pinnedFirst != null) {
      if (result.containsKey(pinnedFirst)) result[pinnedFirst] = 1.0;
      return result;
    }

    final pinnedElsewhere = config.pins.values.toSet();
    final pool = [
      for (final p in config.participants)
        if (!pinnedElsewhere.contains(p.id)) p,
    ];
    if (pool.isEmpty) return result;

    double total = 0;
    for (final p in pool) {
      total += config.weightingEnabled ? max(p.weight, _minWeight) : 1.0;
    }
    for (final p in pool) {
      final w = config.weightingEnabled ? max(p.weight, _minWeight) : 1.0;
      result[p.id] = w / total;
    }
    return result;
  }

  static bool _isPermutation(List<String> order, DraftConfig config) {
    if (order.length != config.size) return false;
    final expected = {for (final p in config.participants) p.id};
    return order.toSet().length == order.length &&
        order.toSet().containsAll(expected) &&
        expected.containsAll(order);
  }
}

/// Top-level helper so heavy generation can run via `compute` off the main
/// thread (closures can't be passed to `compute`).
DraftResult generateInIsolate((DraftConfig, int) args) =>
    DraftEngine.generate(args.$1, seed: args.$2);

/// Convenience for callers that don't care about the mode field.
extension DraftModeResult on DraftMode {
  DraftResult emptyResult() => DraftResult(
    order: const [],
    seed: 0,
    mode: this,
    createdAt: DateTime.now(),
  );
}
