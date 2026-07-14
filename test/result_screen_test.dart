import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_result.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/result_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:draft_race/ui/widgets/confetti_overlay.dart';
import 'package:draft_race/ui/widgets/proof_card.dart';
import 'package:draft_race/ui/widgets/top_picks_podium.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      expect(find.text('Nick'), findsOneWidget);
      expect(find.text('Jordan'), findsOneWidget);
      expect(find.text('Taylor'), findsOneWidget);
    },
  );

  testWidgets('normal-height viewport shows the top picks podium', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    config.addManager('Taylor');
    container.read(draftControllerProvider.notifier).run();

    await tester.pumpWidget(_resultHarness(container));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TopPicksPodium), findsOneWidget);
    expect(find.text('TOP PICK PODIUM'), findsOneWidget);
  });

  testWidgets(
    'short narrow viewport (320x568) shrinks the banner, drops the podium, '
    'and does not overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = await _container();
      addTearDown(container.dispose);

      final config = container.read(draftConfigProvider.notifier);
      // A deliberately long name to stress the pick rows.
      config.addManager('Bartholomew Featherstonehaugh III');
      config.addManager('Jordan');
      config.addManager('Taylor');
      container.read(draftControllerProvider.notifier).run();

      await tester.pumpWidget(_resultHarness(container));
      await tester.pumpAndSettle();

      // Strict: no layout overflow anywhere on the small screen.
      expect(tester.takeException(), isNull);

      // The podium header is omitted to give the board room.
      expect(find.byType(TopPicksPodium), findsNothing);
      expect(find.text('TOP PICK PODIUM'), findsNothing);

      // The champ banner is still there, in its shrunken form.
      expect(find.textContaining('FIRST OVERALL PICK'), findsOneWidget);

      // The MR. IRRELEVANT chip row also stays within bounds.
      final badge = find.text('MR. IRRELEVANT');
      await tester.scrollUntilVisible(badge, 80);
      expect(badge, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('result screen fires the confetti overlay on first build', (
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

    expect(find.byType(ConfettiOverlay), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ConfettiOverlay),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    // Let the burst run out; nothing should throw.
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('last pick row shows MR. IRRELEVANT and first pick does not', (
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

    final ordered = container
        .read(draftControllerProvider)!
        .resolve(container.read(draftConfigProvider).participants);
    final firstName = ordered.first.name;
    final lastName = ordered.last.name;

    final badge = find.text('MR. IRRELEVANT');
    // The board list is lazy; bring the last pick row into view first.
    await tester.scrollUntilVisible(badge, 80);
    expect(badge, findsOneWidget);

    // The badge's pick row holds the last pick's name, not the first pick's.
    final badgeRow = find.ancestor(of: badge, matching: find.byType(Row)).first;
    expect(
      find.descendant(of: badgeRow, matching: find.text(lastName)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: badgeRow, matching: find.text(firstName)),
      findsNothing,
    );
  });

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
    expect(find.byType(ProofCard), findsOneWidget);
    expect(find.text('ORIGINAL DRAW • NO COMMISSIONER EDITS'), findsOneWidget);
    expect(find.text('Share proof image'), findsOneWidget);
  });

  testWidgets('proof image prominently shows commissioner edit history', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    config.addManager('Taylor');
    final controller = container.read(draftControllerProvider.notifier);
    controller.run();
    final original = container.read(draftControllerProvider)!.order;
    controller.editOrder([
      ...original.reversed,
    ], editedAt: DateTime.utc(2026, 7, 14, 1, 2, 3));

    await tester.pumpWidget(_resultHarness(container));
    await tester.tap(find.byTooltip('What this proves'));
    await tester.pumpAndSettle();

    final result = container.read(draftControllerProvider)!;
    expect(find.byType(ProofCard), findsOneWidget);
    expect(find.text(result.proofCode), findsWidgets);
    expect(find.text('COMMISSIONER OVERRIDE • 1 EDIT'), findsOneWidget);
    expect(
      find.textContaining('EDIT 1 • 2026-07-14T01:02:03.000Z'),
      findsOneWidget,
    );
    expect(find.textContaining('BEFORE'), findsOneWidget);
    expect(find.textContaining('AFTER'), findsOneWidget);
    expect(find.textContaining('Commissioner edits: 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('share-proof-image')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the proof code copies it and shows a snackbar', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    config.addManager('Taylor');
    container.read(draftControllerProvider.notifier).run();

    final clipboardCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        clipboardCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_resultHarness(container));

    final proofCode = container.read(draftControllerProvider)!.proofCode;
    await tester.tap(find.text(proofCode));
    await tester.pump();
    await tester.pump();

    final setDataCalls = clipboardCalls.where(
      (call) => call.method == 'Clipboard.setData',
    );
    expect(setDataCalls, hasLength(1));
    expect(
      (setDataCalls.single.arguments as Map<Object?, Object?>)['text'],
      proofCode,
    );
    expect(find.text('Proof code copied'), findsOneWidget);
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

  testWidgets('result screen offers email when saved recipients exist', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);
    const roster = [
      Participant(
        id: 'p1',
        name: 'Nick',
        initials: 'NC',
        email: 'nick@example.com',
        colorValue: 0xFF3A86FF,
      ),
      Participant(
        id: 'p2',
        name: 'Jordan',
        initials: 'JR',
        colorValue: 0xFFE63946,
      ),
    ];
    container
        .read(draftControllerProvider.notifier)
        .setResult(
          DraftResult(
            order: const ['p1', 'p2'],
            seed: 7,
            mode: DraftMode.race,
            createdAt: DateTime.utc(2026, 7, 14),
            rosterSnapshot: roster,
          ),
        );

    await tester.pumpWidget(_resultHarness(container));

    expect(find.text('EMAIL RESULTS'), findsOneWidget);
    expect(find.textContaining('nick@example.com'), findsNothing);
  });

  testWidgets('recap preview sheet does not overflow on a 320x568 screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    config.addManager('Taylor');
    container.read(draftControllerProvider.notifier).run();

    await tester.pumpWidget(_resultHarness(container));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('COPY RECAP'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Share recap'), findsOneWidget);
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
