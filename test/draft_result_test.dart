import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraftResult rosterSnapshot', () {
    test('round-trips saved manager details through json', () {
      final result = DraftResult(
        order: const ['p2', 'p1'],
        seed: 12,
        mode: DraftMode.lottery,
        createdAt: DateTime.utc(2026, 6, 7),
        leagueName: 'Keeper League',
        rosterSnapshot: const [
          Participant(
            id: 'p1',
            name: 'Nick',
            number: '07',
            colorValue: 0xFF3A86FF,
          ),
          Participant(
            id: 'p2',
            name: 'Jordan',
            number: '23',
            colorValue: 0xFFE63946,
          ),
        ],
      );

      final decoded = DraftResult.fromJson(result.toJson());

      expect(decoded.rosterSnapshot, result.rosterSnapshot);
      expect(decoded.resolve(const []).map((p) => p.name), ['Jordan', 'Nick']);
    });

    test('loads older saved results without snapshots', () {
      final decoded = DraftResult.fromJson({
        'order': ['p1'],
        'seed': 99,
        'mode': 'race',
        'createdAt': '2026-06-07T00:00:00.000Z',
      });

      expect(decoded.rosterSnapshot, isEmpty);
      expect(decoded.resolve(const []), isEmpty);
    });

    test('proof code is stable and changes when the order changes', () {
      final base = DraftResult(
        order: const ['p1', 'p2'],
        seed: 12,
        mode: DraftMode.race,
        createdAt: DateTime.utc(2026, 6, 7),
      );
      final same = DraftResult(
        order: const ['p1', 'p2'],
        seed: 12,
        mode: DraftMode.race,
        createdAt: DateTime.utc(2026, 6, 8),
      );
      final saved = base.copyWith(
        rosterSnapshot: const [
          Participant(
            id: 'p1',
            name: 'Nick',
            number: '07',
            colorValue: 0xFF3A86FF,
          ),
          Participant(
            id: 'p2',
            name: 'Jordan',
            number: '23',
            colorValue: 0xFFE63946,
          ),
        ],
      );
      final reordered = base.copyWith(order: const ['p2', 'p1']);

      expect(base.proofCode, same.proofCode);
      expect(base.proofCode, saved.proofCode);
      expect(base.proofCode, isNot(reordered.proofCode));
      expect(base.proofCode, matches(RegExp(r'^DD-[0-9A-Z]{3}-[0-9A-Z]{4}$')));
    });
  });
}
