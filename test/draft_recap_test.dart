import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_recap.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraftRecap.format', () {
    test('formats a league-ready recap with names and jersey numbers', () {
      final recap = DraftRecap.format(
        mode: DraftMode.race,
        leagueName: 'Sunday League',
        proofCode: 'DD-ABC-1234',
        ordered: const [
          Participant(
            id: 'p1',
            name: 'Nick',
            number: '07',
            colorValue: 0xFF000000,
          ),
          Participant(
            id: 'p2',
            name: 'Jordan',
            number: '23',
            colorValue: 0xFF000000,
          ),
        ],
      );

      expect(
        recap,
        [
          'Sunday League draft results',
          'Mode: The Race',
          'Proof code: DD-ABC-1234',
          'First overall: Nick',
          '',
          'Draft board:',
          '1. Nick (#07)',
          '2. Jordan (#23)',
          '',
          'Settled with Draft Dash',
        ].join('\n'),
      );
    });

    test('uses a generic title when the league name is blank', () {
      final recap = DraftRecap.format(
        mode: DraftMode.cards,
        leagueName: '   ',
        ordered: const [],
      );

      expect(
        recap,
        [
          'Draft Dash results',
          'Mode: Card Flip',
          '',
          'Settled with Draft Dash',
        ].join('\n'),
      );
    });
  });
}
