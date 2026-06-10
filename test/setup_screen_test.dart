import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/setup_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:draft_race/ui/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('setup renders the grouped sections on a small viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storageWithManagers();
    await tester.pumpWidget(_setupHarness(storage));
    await tester.pumpAndSettle();

    expect(find.text('FORMAT'), findsOneWidget);
    expect(find.text('MANAGERS'), findsOneWidget);

    for (final label in const [
      'ODDS',
      'LOTTERY OPTIONS',
      'COMMISSIONER',
      'LEAGUE LEDGER',
    ]) {
      await _dragUntilTextVisible(tester, label);
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('each mode detail sheet opens from the setup screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storageWithManagers();
    await tester.pumpWidget(_setupHarness(storage));
    await tester.pumpAndSettle();

    final cases = [
      (summary: 'race animation'),
      (summary: 'one card, one pick'),
      (summary: '14 balls, 4-ball combinations'),
      (summary: 'sold the draft from pick #1 downward'),
    ];

    for (var i = 0; i < cases.length; i++) {
      await tester.tap(find.byIcon(Icons.info_outline_rounded).at(i));
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('mode-detail-${DraftMode.values[i].name}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('mode-detail-summary-${DraftMode.values[i].name}')),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('add manager disables with helper text once the league is full', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storageWithManagers(
      count: DraftConfigController.maxManagers,
    );
    await tester.pumpWidget(_setupHarness(storage));
    await tester.pumpAndSettle();

    await _dragUntilTextVisible(
      tester,
      'League is full (16 max)',
      maxDrags: 30,
    );
    expect(find.text('League is full (16 max)'), findsOneWidget);

    final addButton = tester.widget<GhostButton>(
      find.widgetWithText(GhostButton, '＋ ADD MANAGER'),
    );
    expect(addButton.onPressed, isNull);
  });
}

Future<void> _dragUntilTextVisible(
  WidgetTester tester,
  String label, {
  int maxDrags = 8,
}) async {
  for (var i = 0; i < maxDrags && find.text(label).evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
  }
}

Future<StorageService> _storageWithManagers({int count = 3}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  await storage.saveConfig(
    DraftConfig(
      participants: [
        for (var i = 0; i < count; i++)
          Participant(
            id: 'p${i + 1}',
            name: 'Manager ${i + 1}',
            number: kJerseyNumbers[i % kJerseyNumbers.length],
            colorValue: kJerseyPalette[i % kJerseyPalette.length],
          ),
      ],
      mode: DraftMode.race,
    ),
  );
  return storage;
}

Widget _setupHarness(StorageService storage) => ProviderScope(
  overrides: [storageProvider.overrideWithValue(storage)],
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: const MaterialApp(home: SetupScreen()),
  ),
);
