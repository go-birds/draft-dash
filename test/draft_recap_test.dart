import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_recap.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/league_ledger.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraftRecap.format', () {
    test('formats a league-ready recap with names and jersey numbers', () {
      final recap = DraftRecap.format(
        mode: DraftMode.race,
        leagueName: 'Sunday League',
        proofCode: 'DD-ABC-1234',
        proofMetadata: DraftProofMetadata.fromConfig(
          DraftConfig(
            mode: DraftMode.race,
            weightingEnabled: true,
            reverseOrder: false,
            pins: {0: 'p1'},
            ledgerEntries: [
              LeagueLedgerEntry(
                id: 'ledger-1',
                type: LedgerEntryType.oddsPenalty,
                managerId: 'p2',
                title: 'Missed dues deadline',
                weightDelta: -.5,
                createdAt: DateTime.utc(2026, 6, 8),
              ),
            ],
            participants: [
              Participant(
                id: 'p1',
                name: 'Nick',
                number: '07',
                colorValue: 0xFF000000,
                weight: 2,
                budget: 150,
              ),
              Participant(
                id: 'p2',
                name: 'Jordan',
                number: '23',
                colorValue: 0xFF000000,
                weight: 1,
                budget: 100,
              ),
            ],
          ),
          executedAt: DateTime.utc(2026, 6, 8, 1, 2, 3),
          seed: 42,
        ),
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
          'Executed: 2026-06-08T01:02:03.000Z',
          'Seed: 42',
          'Settings: mode The Race, weighting on, reverse order off, lottery picks 1',
          'Commissioner pins: pick 1=Nick',
          'League Ledger: Jordan odds penalized -0.5x: Missed dues deadline',
          'Manager settings: Nick (#07, weight 2.00, budget 150); Jordan (#23, weight 1.00, budget 100)',
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
