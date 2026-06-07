import 'dart:math';

import 'package:draft_race/domain/draft/auction.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:flutter_test/flutter_test.dart';

List<Participant> roster(List<int> budgets) => [
      for (var i = 0; i < budgets.length; i++)
        Participant(
          id: 'p$i',
          name: 'P$i',
          number: '${i + 1}',
          colorValue: 0xFF000000,
          budget: budgets[i],
        ),
    ];

void main() {
  group('AuctionState', () {
    test('initializes budgets and pick pointer', () {
      final a = AuctionState.initial(roster([100, 100, 50]));
      expect(a.currentPick, 0);
      expect(a.isComplete, isFalse);
      expect(a.budgetOf('p2'), 50);
      expect(a.remainingManagers.length, 3);
    });

    test('high bid wins the pick and pays the amount', () {
      var a = AuctionState.initial(roster([100, 100, 100]));
      a = a.resolveRound({'p0': 40, 'p1': 55, 'p2': 10});
      expect(a.assignedPicks, ['p1']);
      expect(a.budgetOf('p1'), 45); // 100 - 55
      expect(a.budgetOf('p0'), 100); // losers keep their bucks
      expect(a.currentPick, 1);
      expect(a.remainingManagers.map((p) => p.id), ['p0', 'p2']);
    });

    test('bids above remaining budget are clamped', () {
      var a = AuctionState.initial(roster([30, 100, 100]));
      a = a.resolveRound({'p0': 999, 'p1': 35});
      // p0 clamped to 30, loses to p1's 35.
      expect(a.assignedPicks.first, 'p1');
    });

    test('a full auction assigns every manager exactly once', () {
      var a = AuctionState.initial(roster([100, 90, 80, 70]));
      final rng = Random(1);
      var round = 0;
      while (!a.isComplete) {
        // Everyone bids a shrinking amount; deterministic via clamp.
        final bids = {
          for (final p in a.remainingManagers)
            p.id: (a.budgetOf(p.id) - round * 5).clamp(0, a.budgetOf(p.id))
        };
        a = a.resolveRound(bids, rng: rng);
        round++;
      }
      expect(a.assignedPicks.toSet().length, 4);
      final result = a.toResult(seed: 0);
      expect(result.order.length, 4);
    });

    test('commissioner breaks ties in their favor', () {
      var a = AuctionState.initial(roster([100, 100, 100]));
      a = a.resolveRound({'p0': 50, 'p1': 50, 'p2': 50},
          commissionerWinner: 'p2');
      expect(a.assignedPicks.first, 'p2');
    });

    test('no-bid round still awards (keeps the draft moving)', () {
      var a = AuctionState.initial(roster([10, 90, 50]));
      a = a.resolveRound({}); // everyone passes
      // Highest remaining budget (p1) takes it for free.
      expect(a.assignedPicks.first, 'p1');
      expect(a.budgetOf('p1'), 90);
    });

    test('isValidBid enforces budget and eligibility', () {
      var a = AuctionState.initial(roster([40, 100]));
      expect(a.isValidBid('p0', 40), isTrue);
      expect(a.isValidBid('p0', 41), isFalse);
      expect(a.isValidBid('p0', -1), isFalse);
      a = a.resolveRound({'p0': 40});
      expect(a.isValidBid('p0', 0), isFalse); // already won
    });
  });
}
