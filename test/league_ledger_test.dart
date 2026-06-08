import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_engine.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/league_ledger.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:flutter_test/flutter_test.dart';

const _roster = [
  Participant(id: 'p1', name: 'Nick', number: '07', colorValue: 0xFF000000),
  Participant(id: 'p2', name: 'Jordan', number: '23', colorValue: 0xFF000000),
];

void main() {
  group('League Ledger', () {
    test('round-trips through DraftConfig json', () {
      final entry = LeagueLedgerEntry(
        id: 'e1',
        type: LedgerEntryType.oddsPenalty,
        managerId: 'p1',
        title: 'Last place tax',
        notes: 'Finished last in 2025',
        weightDelta: -.5,
        createdAt: DateTime.utc(2026, 6, 8),
      );
      final cfg = DraftConfig(
        participants: _roster,
        mode: DraftMode.lottery,
        ledgerEntries: [entry],
      );

      final decoded = DraftConfig.fromJson(cfg.toJson());

      expect(decoded.ledgerEntries, [entry]);
    });

    test('applies odds modifiers and pick locks before the draft runs', () {
      final cfg = DraftConfig(
        participants: _roster,
        mode: DraftMode.lottery,
        pins: const {1: 'p1'},
        ledgerEntries: [
          LeagueLedgerEntry(
            id: 'e1',
            type: LedgerEntryType.oddsBoost,
            managerId: 'p2',
            title: 'Consolation bracket champ',
            weightDelta: 1,
            createdAt: DateTime.utc(2026, 6, 8),
          ),
          LeagueLedgerEntry(
            id: 'e2',
            type: LedgerEntryType.pickLock,
            managerId: 'p2',
            title: 'Traded for first pick',
            pickIndex: 0,
            createdAt: DateTime.utc(2026, 6, 8),
          ),
        ],
      );

      final applied = cfg.ledgerApplied;
      final result = DraftEngine.generate(cfg, seed: 7);

      expect(applied.participants.last.weight, 2);
      expect(applied.pins, {1: 'p1', 0: 'p2'});
      expect(result.order.first, 'p2');
      expect(result.proofMetadata!.settings.ledgerEntries, cfg.ledgerEntries);
    });
  });
}
