import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/lottery_screen.dart';
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
    'lottery screen advances from live odds to a locked pick and next round',
    (tester) async {
      final container = await _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_harness(container));

      expect(find.text('DRAW BALL 1 OF 4 🎱'), findsOneWidget);
      expect(find.text('LIVE ODDS'), findsOneWidget);
      expect(find.text('BALL 1 OF 4'), findsOneWidget);

      for (var i = 1; i <= 4; i++) {
        final label = 'DRAW BALL $i OF 4 🎱';
        expect(find.text(label), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 950));
      }

      expect(find.text('PICK 1 LOCKED'), findsOneWidget);
      expect(find.textContaining('Winning combo'), findsOneWidget);
      expect(find.text('NEXT PICK'), findsOneWidget);

      await tester.tap(find.text('NEXT PICK'));
      await tester.pump();

      expect(find.text('DRAW BALL 1 OF 4 🎱'), findsOneWidget);
      expect(find.text('LIVE ODDS'), findsOneWidget);
      expect(find.text('BALL 1 OF 4'), findsOneWidget);
    },
  );
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
    const DraftConfig(
      participants: participants,
      mode: DraftMode.lottery,
      lotteryPickCount: 2,
    ),
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
          mode: DraftMode.lottery,
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
    child: const MaterialApp(home: LotteryScreen()),
  ),
);
