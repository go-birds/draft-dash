import 'dart:math';

import 'draft_mode.dart';
import 'draft_result.dart';
import 'participant.dart';

/// One manager's accumulated luck across the saved draft history.
///
/// `luck` for a single draft is `expectedPick − actualPick`, so positive
/// numbers mean the manager kept landing earlier picks than their odds owed
/// them (lucky) and negative numbers mean fate kept shoving them down the
/// board (snake-bitten).
class LuckRecord {
  final String managerId;
  final String name;

  /// Number of drafts that contributed to this record.
  final int drafts;

  /// Sum of per-draft luck values.
  final double totalLuck;

  /// Earliest overall pick number this manager ever landed (1-based).
  final int bestPick;

  /// Latest overall pick number this manager ever landed (1-based).
  final int worstPick;

  const LuckRecord({
    required this.managerId,
    required this.name,
    required this.drafts,
    required this.totalLuck,
    required this.bestPick,
    required this.worstPick,
  });

  double get avgLuck => drafts == 0 ? 0 : totalLuck / drafts;
}

/// Per-manager "luck" computed from saved [DraftResult] history.
///
/// ## Expected-pick math
///
/// The auto-reveal engine ranks managers via Efraimidis–Spirakis weighted
/// sampling without replacement (sort by `pow(u, 1/w)` descending), which is
/// distributionally identical to the Plackett–Luce sequential model: pick #1
/// goes to manager i with probability `w_i / Σw`, pick #2 is drawn the same
/// way from the remainder, and so on.
///
/// Sorting ES keys descending is equivalent to ordering independent
/// exponential "arrival times" `E_i ~ Exp(w_i)` ascending, so for any pair the
/// marginal is `P(j arrives before i) = w_j / (w_i + w_j)`. By linearity of
/// expectation the expected rank is therefore *exact* in closed form:
///
///     E[pick_i] = 1 + Σ_{j ≠ i} w_j / (w_i + w_j)
///
/// No subset DP or large-n fallback is needed — this is exact for every
/// league size and reduces to `(n + 1) / 2` for everyone when weights are
/// equal. The one approximation: lottery mode decides its top picks with
/// NBA-style 14-ball combinations rather than pure ES sampling, so for
/// lottery drafts this is a close approximation rather than exact. Good
/// enough for a fun stat.
///
/// ## Settings handling
///
///  - Bidding/auction drafts are skipped entirely (an auction isn't luck).
///  - Ledger odds boosts/penalties and pick locks are applied first
///    (mirroring `DraftEngine.generate`'s `ledgerApplied` step).
///  - Pinned managers (settings pins + ledger pick locks) are excluded from
///    that draft's luck calc. The remaining pool is compared by its order
///    *within the pool*, which matches how the engine flows non-pinned
///    managers into the unpinned slots.
///  - `reverseOrder` flips the expected position to `(m + 1) − E[rank]`
///    where `m` is the pool size.
///
/// Records are aggregated by participant id, falling back to case-insensitive
/// name matching when ids differ across seasons.
class LeagueStats {
  /// Matches the floor used by `DraftEngine` when sampling.
  static const double _minWeight = 1e-4;

  /// Per-manager records, luckiest (highest average luck) first.
  final List<LuckRecord> records;

  /// Number of history entries that contributed to [records].
  final int draftCount;

  const LeagueStats({required this.records, required this.draftCount});

  LuckRecord? get luckiest => records.isEmpty ? null : records.first;
  LuckRecord? get unluckiest => records.isEmpty ? null : records.last;

  factory LeagueStats.fromHistory(List<DraftResult> history) {
    final byId = <String, _LuckAccumulator>{};
    final byName = <String, _LuckAccumulator>{};
    var draftCount = 0;

    for (final result in history) {
      final meta = result.proofMetadata;
      if (meta == null) continue;
      if (result.mode == DraftMode.bidding) continue;

      final config = meta.settings.ledgerApplied;
      final n = config.size;
      if (n == 0 || result.order.isEmpty) continue;

      // Engine-valid pins only: in-range slot pointing at a real manager.
      final validIds = {for (final p in config.participants) p.id};
      final pinnedIds = <String>{};
      config.pins.forEach((slot, id) {
        if (slot >= 0 && slot < n && validIds.contains(id)) pinnedIds.add(id);
      });

      // The luck pool: non-pinned managers that actually appear in the order.
      final pool = [
        for (final p in config.participants)
          if (!pinnedIds.contains(p.id) && result.pickOf(p.id) > 0) p,
      ];
      if (pool.length < 2) continue; // no luck with nothing to lose

      // Actual rank within the pool (1-based), in board order.
      final poolIds = {for (final p in pool) p.id};
      final poolRank = <String, int>{};
      var rank = 0;
      for (final id in result.order) {
        if (poolIds.contains(id)) poolRank[id] = ++rank;
      }

      final m = pool.length;
      draftCount++;
      for (final p in pool) {
        var expected = _expectedPoolRank(p, pool, config.weightingEnabled);
        if (config.reverseOrder) expected = (m + 1) - expected;
        final luck = expected - poolRank[p.id]!;
        _record(byId, byName, p, luck, result.pickOf(p.id));
      }
    }

    final seen = <_LuckAccumulator>{};
    final records =
        [
          for (final acc in byId.values)
            if (seen.add(acc)) acc.build(),
        ]..sort((a, b) {
          final byLuck = b.avgLuck.compareTo(a.avgLuck);
          return byLuck != 0
              ? byLuck
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

    return LeagueStats(
      records: List<LuckRecord>.unmodifiable(records),
      draftCount: draftCount,
    );
  }

  /// Exact Plackett–Luce expected rank of [p] within [pool] (1-based).
  static double _expectedPoolRank(
    Participant p,
    List<Participant> pool,
    bool weightingEnabled,
  ) {
    if (!weightingEnabled) return (pool.length + 1) / 2;
    final wi = max(p.weight, _minWeight);
    var expected = 1.0;
    for (final other in pool) {
      if (other.id == p.id) continue;
      final wj = max(other.weight, _minWeight);
      expected += wj / (wi + wj);
    }
    return expected;
  }

  static void _record(
    Map<String, _LuckAccumulator> byId,
    Map<String, _LuckAccumulator> byName,
    Participant p,
    double luck,
    int overallPick,
  ) {
    final nameKey = p.name.trim().toLowerCase();
    var acc = byId[p.id];
    if (acc == null && nameKey.isNotEmpty) {
      // Same human, different id across seasons: merge by name.
      acc = byName[nameKey];
      if (acc != null) byId[p.id] = acc;
    }
    if (acc == null) {
      acc = _LuckAccumulator(p.id, p.name);
      byId[p.id] = acc;
      if (nameKey.isNotEmpty) byName[nameKey] = acc;
    }
    acc.add(luck, overallPick);
  }
}

class _LuckAccumulator {
  final String managerId;
  final String name;
  int drafts = 0;
  double totalLuck = 0;
  int bestPick = 1 << 30;
  int worstPick = 0;

  _LuckAccumulator(this.managerId, this.name);

  void add(double luck, int overallPick) {
    drafts++;
    totalLuck += luck;
    bestPick = min(bestPick, overallPick);
    worstPick = max(worstPick, overallPick);
  }

  LuckRecord build() => LuckRecord(
    managerId: managerId,
    name: name,
    drafts: drafts,
    totalLuck: totalLuck,
    bestPick: bestPick,
    worstPick: worstPick,
  );
}
