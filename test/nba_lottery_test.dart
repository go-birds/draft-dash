import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/nba_lottery.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:flutter_test/flutter_test.dart';

List<Participant> roster(List<double> weights) => [
  for (var i = 0; i < weights.length; i++)
    Participant(
      id: 'p$i',
      name: 'P$i',
      number: '${i + 1}',
      colorValue: 0xFF000000,
      weight: weights[i],
    ),
];

void main() {
  group('NbaLottery', () {
    test('assigns exactly 1000 combinations and ignores 11-12-13-14', () {
      final assignment = NbaLotteryAssignment.fromParticipants(
        roster([1, 1, 1]),
        weightingEnabled: true,
      );

      expect(
        assignment.combinationCounts.values.fold<int>(0, (a, b) => a + b),
        NbaLottery.assignedCombinationCount,
      );
      expect(assignment.ownerOf(const [11, 12, 13, 14]), isNull);
    });

    test('distributes combinations proportionally to weights', () {
      final assignment = NbaLotteryAssignment.fromParticipants(
        roster([3, 1]),
        weightingEnabled: true,
      );

      expect(assignment.combinationCounts['p0'], 750);
      expect(assignment.combinationCounts['p1'], 250);
    });

    test('uses equal odds when weighting is disabled', () {
      final assignment = NbaLotteryAssignment.fromParticipants(
        roster([9, 1]),
        weightingEnabled: false,
      );

      expect(assignment.combinationCounts['p0'], 500);
      expect(assignment.combinationCounts['p1'], 500);
    });

    test('defaults to drawing until only one manager remains', () {
      final cfg = DraftConfig(participants: roster([1, 1, 1, 1, 1]));

      final plan = NbaLottery.generate(cfg, seed: 7);

      expect(plan.rounds, hasLength(4));
      expect(plan.order, hasLength(5));
      expect(plan.order.toSet(), {for (final p in cfg.participants) p.id});
      expect(plan.rounds.map((r) => r.winnerId).toSet(), hasLength(4));
      for (final round in plan.rounds) {
        expect(round.balls, hasLength(4));
        expect(round.balls, orderedEquals([...round.balls]..sort()));
      }
    });

    test('can draw a configured number of lottery picks before filling', () {
      final cfg = DraftConfig(
        participants: roster([1, 1, 1, 1, 1]),
        lotteryPickCount: 2,
      );

      final plan = NbaLottery.generate(cfg, seed: 7);

      expect(plan.rounds, hasLength(2));
      expect(plan.order, hasLength(5));
      expect(plan.rounds.map((r) => r.winnerId).toSet(), hasLength(2));
      expect(plan.order.toSet(), {for (final p in cfg.participants) p.id});
    });

    test('can skip lottery picks and fill the board deterministically', () {
      final cfg = DraftConfig(
        participants: roster([1, 1, 1, 1, 1]),
        lotteryPickCount: 0,
      );

      final plan = NbaLottery.generate(cfg, seed: 7);

      expect(plan.rounds, isEmpty);
      expect(plan.order, hasLength(5));
      expect(plan.order.toSet(), {for (final p in cfg.participants) p.id});
    });

    test(
      'updates chances after drawn balls and eliminates impossible teams',
      () {
        final assignment = NbaLotteryAssignment.fromParticipants(
          roster([3, 1]),
          weightingEnabled: true,
        );
        final p1Combo = assignment.combinationsByOwner['p1']!.first;

        final firstBallChances = assignment.chancesAfter(
          drawnBalls: [p1Combo.first],
        );
        final fullComboChances = assignment.chancesAfter(drawnBalls: p1Combo);

        expect(
          firstBallChances.values.fold<double>(0, (a, b) => a + b),
          closeTo(1, 1e-9),
        );
        expect(fullComboChances['p1'], 1);
        expect(fullComboChances['p0'], 0);
      },
    );
  });
}
