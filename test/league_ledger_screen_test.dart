import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/league_ledger.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/league_ledger_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _managers = [
  Participant(id: 'p1', name: 'Nick', number: '07', colorValue: 0xFF3A86FF),
  Participant(id: 'p2', name: 'Jordan', number: '23', colorValue: 0xFFE63946),
];

void main() {
  testWidgets('template creates an odds penalty entry', (tester) async {
    final storage = await _storageWithManagers();

    await tester.pumpWidget(_ledgerHarness(storage));

    await tester.tap(find.text('ADD LEDGER ENTRY'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Last-place penalty'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('SAVE ENTRY'));
    await tester.tap(find.text('SAVE ENTRY'));
    await tester.pumpAndSettle();

    final cfg = storage.loadConfig();
    expect(cfg?.ledgerEntries, hasLength(1));

    final entry = cfg!.ledgerEntries.single;
    expect(entry.type, LedgerEntryType.oddsPenalty);
    expect(entry.title, 'Last-place penalty');
    expect(entry.notes, contains('Penalize the manager who finishes last.'));
    expect(entry.weightDelta, -.5);
  });

  testWidgets('template creates a pick-lock entry', (tester) async {
    final storage = await _storageWithManagers();

    await tester.pumpWidget(_ledgerHarness(storage));

    await tester.tap(find.text('ADD LEDGER ENTRY'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Traded / locked pick'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('SAVE ENTRY'));
    await tester.tap(find.text('SAVE ENTRY'));
    await tester.pumpAndSettle();

    final cfg = storage.loadConfig();
    expect(cfg?.ledgerEntries, hasLength(1));

    final entry = cfg!.ledgerEntries.single;
    expect(entry.type, LedgerEntryType.pickLock);
    expect(entry.title, 'Traded / locked pick');
    expect(entry.notes, contains('Keep this pick locked'));
    expect(entry.pickIndex, 0);
  });

  testWidgets('ledger entry sheet does not overflow on a 320x568 screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = await _storageWithManagers();
    await tester.pumpWidget(_ledgerHarness(storage));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ADD LEDGER ENTRY'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ADD TO LEAGUE LEDGER'), findsOneWidget);

    // The sheet stays scrollable, so the save button can be reached.
    await tester.ensureVisible(find.text('SAVE ENTRY'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<StorageService> _storageWithManagers() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  await storage.saveConfig(
    const DraftConfig(participants: _managers, mode: DraftMode.lottery),
  );
  return storage;
}

Widget _ledgerHarness(StorageService storage) => ProviderScope(
  overrides: [storageProvider.overrideWithValue(storage)],
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: const MaterialApp(home: LeagueLedgerScreen()),
  ),
);
