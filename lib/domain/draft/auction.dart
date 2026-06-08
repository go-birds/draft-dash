import 'dart:math';

import 'draft_mode.dart';
import 'draft_result.dart';
import 'participant.dart';

/// Live ColemanBucks auction. Picks are sold from #1 downward; for each pick a
/// sealed-bid round runs, the high bid wins and pays, and remaining budgets
/// carry forward. Pure & immutable — the controller drives the rounds.
class AuctionState {
  final List<Participant> participants;

  /// id -> ColemanBucks still available to bid.
  final Map<String, int> remainingBudgets;

  /// Winners so far, in pick order. `assignedPicks[0]` won pick #1.
  final List<String> assignedPicks;

  const AuctionState({
    required this.participants,
    required this.remainingBudgets,
    required this.assignedPicks,
  });

  factory AuctionState.initial(List<Participant> participants) => AuctionState(
    participants: participants,
    remainingBudgets: {for (final p in participants) p.id: p.budget},
    assignedPicks: const [],
  );

  /// 0-based index of the pick currently up for bid.
  int get currentPick => assignedPicks.length;

  bool get isComplete => assignedPicks.length == participants.length;

  /// Managers who have not yet won a pick (eligible to bid this round).
  List<Participant> get remainingManagers {
    final won = assignedPicks.toSet();
    return [
      for (final p in participants)
        if (!won.contains(p.id)) p,
    ];
  }

  int budgetOf(String id) => remainingBudgets[id] ?? 0;

  /// Validate a single bid for the current round.
  bool isValidBid(String id, int amount) {
    if (assignedPicks.contains(id)) return false;
    if (amount < 0) return false;
    return amount <= budgetOf(id);
  }

  /// Resolve a sealed-bid round.
  ///
  /// [bids] maps eligible manager id -> bid (omit or 0 to pass). The high bid
  /// wins, pays its amount, and takes the current pick. Ties are broken by
  /// [commissionerWinner] when it is among the tied leaders, otherwise by
  /// [rng] (deterministic when seeded), otherwise the first tied id.
  AuctionState resolveRound(
    Map<String, int> bids, {
    String? commissionerWinner,
    Random? rng,
  }) {
    if (isComplete) return this;

    final eligible = {for (final p in remainingManagers) p.id};
    // Sanitize: clamp to valid range; ignore unknown/already-won bidders.
    final clean = <String, int>{};
    for (final p in remainingManagers) {
      final raw = bids[p.id] ?? 0;
      clean[p.id] = raw.clamp(0, budgetOf(p.id));
    }

    final highBid = clean.values.fold<int>(0, (m, b) => b > m ? b : m);

    String winner;
    if (highBid <= 0) {
      // Nobody bid — award to the manager with the most budget (deterministic),
      // ties broken by rng/first. Keeps the draft moving.
      final ids = eligible.toList()
        ..sort((a, b) => budgetOf(b).compareTo(budgetOf(a)));
      winner = _breakTie(
        ids.where((id) => budgetOf(id) == budgetOf(ids.first)).toList(),
        commissionerWinner,
        rng,
      );
    } else {
      final top = [
        for (final e in clean.entries)
          if (e.value == highBid) e.key,
      ];
      winner = _breakTie(top, commissionerWinner, rng);
    }

    final paid = highBid > 0 ? clean[winner]! : 0;
    final nextBudgets = Map<String, int>.from(remainingBudgets);
    nextBudgets[winner] = (nextBudgets[winner] ?? 0) - paid;

    return AuctionState(
      participants: participants,
      remainingBudgets: nextBudgets,
      assignedPicks: [...assignedPicks, winner],
    );
  }

  static String _breakTie(
    List<String> tied,
    String? commissionerWinner,
    Random? rng,
  ) {
    if (tied.length == 1) return tied.first;
    if (commissionerWinner != null && tied.contains(commissionerWinner)) {
      return commissionerWinner;
    }
    if (rng != null) return tied[rng.nextInt(tied.length)];
    return tied.first;
  }

  /// Once complete, the finished draft order.
  DraftResult toResult({required int seed}) => DraftResult(
    order: List<String>.from(assignedPicks),
    seed: seed,
    mode: DraftMode.bidding,
    createdAt: DateTime.now(),
    rosterSnapshot: List<Participant>.unmodifiable(participants),
  );
}
