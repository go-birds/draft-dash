import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:draft_race/ui/widgets/manager_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('handicap setup shows independent multipliers, not percentages', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.open();
    await storage.saveConfig(
      const DraftConfig(
        participants: [
          Participant(
            id: 'p1',
            name: 'Nick',
            number: '07',
            colorValue: 0xFF3A86FF,
            weight: 1,
          ),
          Participant(
            id: 'p2',
            name: 'Jordan',
            number: '23',
            colorValue: 0xFFE63946,
            weight: 3,
          ),
        ],
        weightingEnabled: true,
      ),
    );

    await tester.pumpWidget(_managerTileHarness(storage));

    expect(find.text('1.0×'), findsOneWidget);
    expect(find.text('3.0×'), findsOneWidget);
    expect(find.text('pick 1'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('manager removal can be undone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.open();
    await storage.saveConfig(
      const DraftConfig(
        participants: [
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
        pins: {0: 'p1'},
      ),
    );

    await tester.pumpWidget(_managerTileHarness(storage));

    expect(find.text('Nick'), findsOneWidget);
    expect(find.text('Jordan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();

    expect(find.text('Nick'), findsNothing);
    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('Nick removed'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();

    expect(find.text('Nick'), findsOneWidget);
    expect(find.text('Jordan'), findsOneWidget);
  });
}

Widget _managerTileHarness(StorageService storage) => ProviderScope(
  overrides: [storageProvider.overrideWithValue(storage)],
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) {
            final cfg = ref.watch(draftConfigProvider);
            return ListView(
              children: [
                for (final p in cfg.participants)
                  ManagerTile(
                    p: p,
                    mode: DraftMode.race,
                    weightingEnabled: true,
                  ),
              ],
            );
          },
        ),
      ),
    ),
  ),
);
