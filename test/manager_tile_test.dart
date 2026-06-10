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

  group('name validation', () {
    testWidgets('empty name is rejected and prior name kept on dismiss', (
      tester,
    ) async {
      final storage = await _twoManagerStorage();
      await tester.pumpWidget(_managerTileHarness(storage));

      await _openEditDialog(tester, 'Nick');
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text("Name can't be empty"), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Nick'), findsOneWidget);
    });

    testWidgets('whitespace-only name is rejected', (tester) async {
      final storage = await _twoManagerStorage();
      await tester.pumpWidget(_managerTileHarness(storage));

      await _openEditDialog(tester, 'Nick');
      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text("Name can't be empty"), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('name input is limited to 24 characters', (tester) async {
      final storage = await _twoManagerStorage();
      await tester.pumpWidget(_managerTileHarness(storage));

      await _openEditDialog(tester, 'Nick');
      await tester.enterText(find.byType(TextField).first, 'A' * 30);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('A' * 24), findsOneWidget);
      expect(find.text('A' * 30), findsNothing);
    });

    testWidgets('duplicate name is rejected case-insensitively', (
      tester,
    ) async {
      final storage = await _twoManagerStorage();
      await tester.pumpWidget(_managerTileHarness(storage));

      await _openEditDialog(tester, 'Nick');
      await tester.enterText(find.byType(TextField).first, 'jordan');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Name already taken'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('renaming to own name (different case) is allowed', (
      tester,
    ) async {
      final storage = await _twoManagerStorage();
      await tester.pumpWidget(_managerTileHarness(storage));

      await _openEditDialog(tester, 'Nick');
      await tester.enterText(find.byType(TextField).first, 'NICK');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name already taken'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('NICK'), findsOneWidget);
    });
  });

  group('jersey number validation', () {
    testWidgets('jersey input keeps digits only, max two', (tester) async {
      final storage = await _singleManagerStorage(number: '23');
      await tester.pumpWidget(_managerTileHarness(storage));

      await _openEditDialog(tester, 'Nick');
      await tester.enterText(find.byType(TextField).last, 'a1b2c3');

      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.controller!.text, '12');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('single digit jersey is padded to two digits', (tester) async {
      final storage = await _singleManagerStorage(number: '23');
      await tester.pumpWidget(_managerTileHarness(storage));

      await _openEditDialog(tester, 'Nick');
      await tester.enterText(find.byType(TextField).last, '7');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('07'), findsOneWidget);
      expect(find.text('7'), findsNothing);
    });

    testWidgets('empty jersey keeps the previous number', (tester) async {
      final storage = await _singleManagerStorage(number: '23');
      await tester.pumpWidget(_managerTileHarness(storage));

      await _openEditDialog(tester, 'Nick');
      await tester.enterText(find.byType(TextField).last, '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('23'), findsOneWidget);
    });
  });
}

Future<StorageService> _twoManagerStorage() async {
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
    ),
  );
  return storage;
}

Future<StorageService> _singleManagerStorage({required String number}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  await storage.saveConfig(
    DraftConfig(
      participants: [
        Participant(
          id: 'p1',
          name: 'Nick',
          number: number,
          colorValue: 0xFF3A86FF,
        ),
      ],
    ),
  );
  return storage;
}

Future<void> _openEditDialog(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
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
