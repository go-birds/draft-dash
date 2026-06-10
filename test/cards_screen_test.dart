import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/cards_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _names = ['NICK', 'JORDAN', 'TAYLOR', 'AVERY', 'SAM'];

void main() {
  testWidgets('cards screen starts with all cards face-down and a tap prompt', (
    tester,
  ) async {
    await _setUp(tester);

    expect(find.text('CARD FLIP DRAFT'), findsOneWidget);
    expect(find.text('TAP TO REVEAL'), findsOneWidget);
    expect(find.text('0 of 5 picks revealed'), findsOneWidget);
    // All five card backs are face-down; only the first invites a tap.
    expect(find.text('🏈'), findsNWidgets(5));
    expect(find.text('TAP!'), findsOneWidget);
    expect(find.text('PICK 1'), findsOneWidget);
    expect(find.text('⤓ REVEAL ALL'), findsOneWidget);
    // No manager name is revealed yet.
    for (final name in _names) {
      expect(find.text(name), findsNothing);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('flipping cards one at a time reveals managers in draft order', (
    tester,
  ) async {
    await _setUp(tester);

    for (var i = 0; i < _names.length; i++) {
      // Only the next card in pick order shows the TAP! hint.
      await tester.tap(find.text('TAP!'));
      await tester.pumpAndSettle();

      expect(find.text('${i + 1} of 5 picks revealed'), findsOneWidget);
      // Everything revealed so far stays visible, later picks stay hidden.
      for (var j = 0; j < _names.length; j++) {
        expect(find.text(_names[j]), j <= i ? findsOneWidget : findsNothing);
      }
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing all flips shows the board-set state and results CTA', (
    tester,
  ) async {
    await _setUp(tester);

    for (var i = 0; i < _names.length; i++) {
      await tester.tap(find.text('TAP!'));
      await tester.pumpAndSettle();
    }

    expect(find.text('THE BOARD IS SET'), findsOneWidget);
    expect(find.text('5 of 5 picks revealed'), findsOneWidget);
    expect(find.text('SEE THE BOARD ✓'), findsOneWidget);
    expect(find.text('⤓ REVEAL ALL'), findsNothing);
    expect(find.text('TAP!'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('reveal-all flips every remaining card at once', (tester) async {
    await _setUp(tester);

    await tester.tap(find.text('⤓ REVEAL ALL'));
    await tester.pumpAndSettle();

    for (final name in _names) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('THE BOARD IS SET'), findsOneWidget);
    expect(find.text('SEE THE BOARD ✓'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

/// Pumps the cards screen with a deterministic seeded draft result.
///
/// The grid lays out five cards in three rows, so the test surface is made
/// tall enough that every card is on screen and tappable without scrolling.
Future<void> _setUp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = await _container();
  addTearDown(container.dispose);

  await tester.pumpWidget(_harness(container));
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  const participants = [
    Participant(id: 'p1', name: 'Nick', number: '07', colorValue: 0xFF3A86FF),
    Participant(id: 'p2', name: 'Jordan', number: '23', colorValue: 0xFFE63946),
    Participant(id: 'p3', name: 'Taylor', number: '12', colorValue: 0xFFFFB703),
    Participant(id: 'p4', name: 'Avery', number: '05', colorValue: 0xFF06D6A0),
    Participant(id: 'p5', name: 'Sam', number: '88', colorValue: 0xFF9B5DE5),
  ];
  await storage.saveConfig(
    const DraftConfig(participants: participants, mode: DraftMode.cards),
  );

  final container = ProviderContainer(
    overrides: [storageProvider.overrideWithValue(storage)],
  );
  container
      .read(draftControllerProvider.notifier)
      .setResult(
        DraftResult(
          order: const ['p1', 'p2', 'p3', 'p4', 'p5'],
          seed: 7,
          mode: DraftMode.cards,
          createdAt: DateTime.utc(2026, 6, 7),
          rosterSnapshot: participants,
        ),
      );
  return container;
}

Widget _harness(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: const MaterialApp(home: CardsScreen()),
  ),
);
