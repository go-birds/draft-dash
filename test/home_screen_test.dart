import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/league_ledger.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/navigation/app_router.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first-run empty state shows the setup guidance', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storageWithoutLeague();

    await tester.pumpWidget(_homeHarness(storage));
    await tester.pumpAndSettle();

    expect(find.text('CREATE LEAGUE'), findsOneWidget);
    expect(find.text('DRAFT'), findsNWidgets(2));
    expect(find.text('PRIMARY ACTION'), findsNothing);
    expect(find.text('No saved league yet'), findsOneWidget);
    expect(find.text('Create league'), findsOneWidget);
    expect(find.text('Add managers'), findsOneWidget);
    expect(find.text('Choose reveal mode'), findsOneWidget);
    expect(find.text('Run draft'), findsOneWidget);
    expect(find.text('Save/share recap'), findsOneWidget);
    expect(find.text('OPEN LEAGUE LEDGER · 0 ENTRIES'), findsOneWidget);

    await tester.tap(find.text('CREATE LEAGUE'));
    await tester.pumpAndSettle();

    expect(find.text('LEAGUE NAME'), findsOneWidget);
  });

  testWidgets(
    'saved league state shows quick actions and resets on new draft',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = await _storageWithLeague();

      await tester.pumpWidget(_homeHarness(storage));
      await tester.pumpAndSettle();

      expect(find.text('NEW DRAFT'), findsOneWidget);
      expect(find.text('EDIT SAVED LEAGUE'), findsOneWidget);
      expect(find.text('SUNDAY LEAGUE'), findsOneWidget);
      expect(find.text('3 managers'), findsOneWidget);
      expect(find.text('2 ledger entries'), findsOneWidget);
      expect(find.text('OPEN LEAGUE LEDGER · 2 ENTRIES'), findsOneWidget);

      await tester.tap(find.text('NEW DRAFT'));
      await tester.pumpAndSettle();

      expect(find.text('LEAGUE NAME'), findsOneWidget);

      final saved = storage.loadConfig();
      expect(saved?.weightingEnabled, isFalse);
      expect(saved?.reverseOrder, isFalse);
      expect(saved?.pins, isEmpty);
      expect(saved?.participants.map((p) => p.weight), [1, 1, 1]);
    },
  );
}

Future<StorageService> _storageWithoutLeague() async {
  SharedPreferences.setMockInitialValues({});
  return StorageService.open();
}

Future<StorageService> _storageWithLeague() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  const managers = [
    Participant(id: 'p1', name: 'Nick', initials: 'NC', colorValue: 0xFF3A86FF),
    Participant(
      id: 'p2',
      name: 'Jordan',
      initials: 'JS',
      colorValue: 0xFFE63946,
    ),
    Participant(
      id: 'p3',
      name: 'Taylor',
      initials: 'TR',
      colorValue: 0xFFFFB703,
    ),
  ];
  await storage.setLeagueName('Sunday League');
  await storage.saveConfig(
    DraftConfig(
      participants: managers,
      mode: DraftMode.lottery,
      weightingEnabled: true,
      reverseOrder: true,
      pins: {0: 'p1'},
      ledgerEntries: [
        LeagueLedgerEntry(
          id: 'e1',
          type: LedgerEntryType.note,
          managerId: 'p2',
          title: 'Keep an eye on waivers',
          notes: 'Bring up trade chatter before kickoff.',
          createdAt: DateTime.utc(2026, 6, 8),
        ),
        LeagueLedgerEntry(
          id: 'e2',
          type: LedgerEntryType.pickLock,
          managerId: 'p3',
          title: 'Locked to third',
          pickIndex: 2,
          createdAt: DateTime.utc(2026, 6, 8),
        ),
      ],
    ),
  );
  return storage;
}

Widget _homeHarness(StorageService storage) => ProviderScope(
  overrides: [storageProvider.overrideWithValue(storage)],
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: MaterialApp(
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    ),
  ),
);
