import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/result_screen.dart';
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
    'result screen keeps showing the board after league data clears',
    (tester) async {
      final container = await _container();
      addTearDown(container.dispose);

      final config = container.read(draftConfigProvider.notifier);
      config.addManager('Nick');
      config.addManager('Jordan');
      config.addManager('Taylor');
      container.read(draftControllerProvider.notifier).run();
      config.clearLeague();

      await tester.pumpWidget(_resultHarness(container));

      expect(find.textContaining('FIRST OVERALL PICK'), findsOneWidget);
      expect(find.text('TOP PICK PODIUM'), findsOneWidget);
      expect(find.text('Nick'), findsOneWidget);
      expect(find.text('Jordan'), findsOneWidget);
      expect(find.text('Taylor'), findsOneWidget);
    },
  );

  testWidgets('result screen falls back when manager details are missing', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    container
        .read(draftControllerProvider.notifier)
        .setResult(
          DraftResult(
            order: const ['missing-manager'],
            seed: 1,
            mode: DraftMode.race,
            createdAt: DateTime.utc(2026, 6, 7),
          ),
        );

    await tester.pumpWidget(_resultHarness(container));

    expect(find.text('Draft details unavailable'), findsOneWidget);
    expect(find.text('BACK TO SETUP'), findsOneWidget);
  });

  testWidgets('result screen falls back when only part of the board resolves', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    container
        .read(draftControllerProvider.notifier)
        .setResult(
          DraftResult(
            order: const ['p1', 'missing-manager'],
            seed: 1,
            mode: DraftMode.race,
            createdAt: DateTime.utc(2026, 6, 7),
            rosterSnapshot: const [
              Participant(
                id: 'p1',
                name: 'Nick',
                number: '07',
                colorValue: 0xFF3A86FF,
              ),
            ],
          ),
        );

    await tester.pumpWidget(_resultHarness(container));

    expect(find.text('Draft details unavailable'), findsOneWidget);
    expect(find.text('Nick'), findsNothing);
  });

  testWidgets('result screen opens the proof explainer', (tester) async {
    final container = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    config.addManager('Taylor');
    container.read(draftControllerProvider.notifier).run();

    await tester.pumpWidget(_resultHarness(container));

    await tester.tap(find.byTooltip('What this proves'));
    await tester.pumpAndSettle();

    expect(find.text('What this proves'), findsOneWidget);
    expect(find.textContaining('Proof code:'), findsOneWidget);
    expect(find.textContaining('Executed at:'), findsOneWidget);
    expect(find.textContaining('Settings metadata:'), findsOneWidget);
    expect(find.textContaining('League Ledger:'), findsOneWidget);
  });

  testWidgets('result screen opens recap preview before copying', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    config.addManager('Taylor');
    container.read(draftControllerProvider.notifier).run();

    await tester.pumpWidget(_resultHarness(container));

    await tester.tap(find.text('COPY RECAP'));
    await tester.pumpAndSettle();

    expect(find.text('Share recap'), findsOneWidget);
    expect(find.text('COPY SHORT RECAP'), findsOneWidget);
    expect(find.text('COPY FULL PROOF RECAP'), findsOneWidget);
  });
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  return ProviderContainer(
    overrides: [storageProvider.overrideWithValue(storage)],
  );
}

Widget _resultHarness(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: const MaterialApp(home: ResultScreen()),
  ),
);
