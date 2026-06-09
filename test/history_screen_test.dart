import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/league_ledger.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/history_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('history clear requires confirmation', (tester) async {
    final storage = await _storageWithHistory([_savedResult()]);

    await tester.pumpWidget(_historyHarness(storage));

    expect(find.text('Sunday League'), findsOneWidget);
    expect(storage.loadHistory(), hasLength(1));

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Clear draft history?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Sunday League'), findsOneWidget);
    expect(storage.loadHistory(), hasLength(1));

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();

    expect(find.text('No drafts yet'), findsOneWidget);
    expect(storage.loadHistory(), isEmpty);
  });

  testWidgets('opens a full saved draft board from history', (tester) async {
    final storage = await _storageWithHistory([_savedResult()]);

    await tester.pumpWidget(_historyHarness(storage));

    await tester.tap(find.text('Sunday League'));
    await tester.pumpAndSettle();

    expect(find.text('SAVED BOARD'), findsOneWidget);
    expect(find.text('FULL DRAFT BOARD'), findsOneWidget);
    expect(find.text('FIRST OVERALL'), findsOneWidget);
    expect(find.text('TOP PICK PODIUM'), findsOneWidget);
    expect(find.text('Nick'), findsWidgets);
    expect(find.text('Jordan'), findsWidgets);
    expect(find.text('Taylor'), findsWidgets);
    expect(find.text('COPY RECAP'), findsOneWidget);
  });

  testWidgets('saved board detail falls back when manager data is incomplete', (
    tester,
  ) async {
    final storage = await _storageWithHistory([
      DraftResult(
        order: const ['p1', 'missing-manager'],
        seed: 42,
        mode: DraftMode.race,
        createdAt: DateTime.utc(2026, 6, 7),
        leagueName: 'Old League',
        rosterSnapshot: const [
          Participant(
            id: 'p1',
            name: 'Nick',
            number: '07',
            colorValue: 0xFF3A86FF,
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(_historyHarness(storage));

    expect(find.text('Manager details unavailable'), findsOneWidget);
    expect(find.byTooltip('Copy recap'), findsNothing);

    await tester.tap(find.text('Old League'));
    await tester.pumpAndSettle();

    expect(find.text('Saved board details unavailable'), findsOneWidget);
    expect(find.text('Nick'), findsNothing);
  });

  testWidgets('saved board detail opens the proof explainer', (tester) async {
    final storage = await _storageWithHistory([_savedResultWithProof()]);

    await tester.pumpWidget(_historyHarness(storage));

    await tester.tap(find.text('Sunday League'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('What this proves'));
    await tester.pumpAndSettle();

    expect(find.text('What this proves'), findsOneWidget);
    expect(find.textContaining('Proof code:'), findsOneWidget);
    expect(find.textContaining('Executed at:'), findsOneWidget);
    expect(find.textContaining('Settings metadata:'), findsOneWidget);
    expect(find.textContaining('League Ledger:'), findsOneWidget);
  });
}

DraftResult _savedResult() => DraftResult(
  order: const ['p1', 'p2', 'p3'],
  seed: 42,
  mode: DraftMode.race,
  createdAt: DateTime.utc(2026, 6, 7),
  leagueName: 'Sunday League',
  rosterSnapshot: const [
    Participant(id: 'p1', name: 'Nick', number: '07', colorValue: 0xFF3A86FF),
    Participant(id: 'p2', name: 'Jordan', number: '23', colorValue: 0xFFE63946),
    Participant(id: 'p3', name: 'Taylor', number: '12', colorValue: 0xFFFFB703),
  ],
);

DraftResult _savedResultWithProof() => DraftResult(
  order: const ['p1', 'p2', 'p3'],
  seed: 42,
  mode: DraftMode.race,
  createdAt: DateTime.utc(2026, 6, 7),
  leagueName: 'Sunday League',
  rosterSnapshot: const [
    Participant(id: 'p1', name: 'Nick', number: '07', colorValue: 0xFF3A86FF),
    Participant(id: 'p2', name: 'Jordan', number: '23', colorValue: 0xFFE63946),
    Participant(id: 'p3', name: 'Taylor', number: '12', colorValue: 0xFFFFB703),
  ],
  proofMetadata: DraftProofMetadata.fromConfig(
    DraftConfig(
      mode: DraftMode.race,
      weightingEnabled: true,
      reverseOrder: false,
      pins: {0: 'p1'},
      ledgerEntries: [
        LeagueLedgerEntry(
          id: 'ledger-1',
          type: LedgerEntryType.note,
          managerId: 'p2',
          title: 'Keeper note',
          createdAt: DateTime.utc(2026, 6, 6),
        ),
      ],
      participants: const [
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
        Participant(
          id: 'p3',
          name: 'Taylor',
          number: '12',
          colorValue: 0xFFFFB703,
        ),
      ],
    ),
    executedAt: DateTime.utc(2026, 6, 7, 12, 34, 56),
    seed: 42,
  ),
);

Future<StorageService> _storageWithHistory(List<DraftResult> history) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  await storage.saveHistory(history);
  return storage;
}

Widget _historyHarness(StorageService storage) => ProviderScope(
  overrides: [storageProvider.overrideWithValue(storage)],
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: const MaterialApp(home: HistoryScreen()),
  ),
);
