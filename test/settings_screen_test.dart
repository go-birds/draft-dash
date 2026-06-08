import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/settings_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'saved league clear requires confirmation and preserves history',
    (tester) async {
      final storage = await _storageWithLeague();

      await tester.pumpWidget(_settingsHarness(storage));

      expect(storage.loadConfig()?.participants, hasLength(2));
      expect(storage.leagueName, 'Sunday League');
      expect(storage.loadHistory(), hasLength(1));

      await tester.tap(find.text('Clear saved league'));
      await tester.pumpAndSettle();

      expect(find.text('Clear saved league?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(storage.loadConfig()?.participants, hasLength(2));
      expect(storage.leagueName, 'Sunday League');
      expect(storage.loadHistory(), hasLength(1));

      await tester.tap(find.text('Clear saved league'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear league'));
      await tester.pumpAndSettle();

      expect(storage.loadConfig()?.participants, isEmpty);
      expect(storage.leagueName, isEmpty);
      expect(storage.loadHistory(), hasLength(1));
    },
  );
}

Future<StorageService> _storageWithLeague() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  const managers = [
    Participant(id: 'p1', name: 'Nick', number: '07', colorValue: 0xFF3A86FF),
    Participant(id: 'p2', name: 'Jordan', number: '23', colorValue: 0xFFE63946),
  ];
  await storage.setLeagueName('Sunday League');
  await storage.saveConfig(
    const DraftConfig(
      participants: managers,
      mode: DraftMode.lottery,
      pins: {0: 'p1'},
    ),
  );
  await storage.saveHistory([
    DraftResult(
      order: const ['p2', 'p1'],
      seed: 99,
      mode: DraftMode.lottery,
      createdAt: DateTime.utc(2026, 6, 7),
      leagueName: 'Sunday League',
      rosterSnapshot: managers,
    ),
  ]);
  return storage;
}

Widget _settingsHarness(StorageService storage) => ProviderScope(
  overrides: [storageProvider.overrideWithValue(storage)],
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: const MaterialApp(home: SettingsScreen()),
  ),
);
