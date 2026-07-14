import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/cards_screen.dart';
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
    await _dragUntilTextVisible(tester, 'MANAGERS');
    expect(find.text('MANAGERS'), findsOneWidget);

    for (final label in const [
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
      find.widgetWithText(GhostButton, '＋ ADD MANAGERS'),
    );
    expect(addButton.onPressed, isNull);
  });

  testWidgets('empty roster shows the empty state until a manager is added', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storageWithManagers(count: 0);
    await tester.pumpWidget(_setupHarness(storage));
    await tester.pumpAndSettle();

    const emptyText = 'No managers yet — add your league to get started';
    await _dragUntilTextVisible(tester, emptyText);
    expect(find.text(emptyText), findsOneWidget);

    await _dragUntilHitTestable(tester, find.text('ADD MANAGERS'));
    await tester.tap(find.text('ADD MANAGERS'));
    await tester.pumpAndSettle();

    expect(find.text('How do you want to build the roster?'), findsOneWidget);
    expect(find.text('ENTER MANUALLY'), findsOneWidget);
    expect(find.text('UPLOAD CSV'), findsOneWidget);
  });

  testWidgets('manual roster entry creates the selected number in one form', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await _storageWithManagers(count: 0);
    await tester.pumpWidget(_setupHarness(storage));
    await tester.pumpAndSettle();

    await _dragUntilHitTestable(tester, find.text('ADD MANAGERS'));
    await tester.tap(find.text('ADD MANAGERS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENTER MANUALLY'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual-manager-count')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('manager-name-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('manager-name-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('manager-name-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('manager-name-3')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('manager-name-0')),
      'Nick Coleman',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manager-email-0')),
      'nick@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manager-name-1')),
      'Jordan Smith',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manager-name-2')),
      'Taylor Reed',
    );
    await tester.ensureVisible(find.text('ADD TO LEAGUE'));
    await tester.tap(find.text('ADD TO LEAGUE'));
    await tester.pumpAndSettle();

    final managers = storage.loadConfig()!.participants;
    expect(managers, hasLength(3));
    expect(managers.first.name, 'Nick Coleman');
    expect(managers.first.initials, 'NC');
    expect(managers.first.email, 'nick@example.com');
    expect(managers[1].initials, 'JS');
    expect(managers.last.initials, 'TR');
  });

  testWidgets(
    'handicap control appears above managers and makes impact clear',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _storageWithManagers();
      await tester.pumpWidget(_setupHarness(storage));
      await tester.pumpAndSettle();

      final toggle = find.text('⚖ HANDICAP ODDS');
      await _dragUntilTextVisible(tester, '⚖ HANDICAP ODDS');
      expect(toggle, findsOneWidget);
      expect(
        tester.getTopLeft(toggle).dy,
        lessThan(tester.getTopLeft(find.text('Manager 1')).dy),
      );
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(
        find.text('ON · Each manager now has an odds control below.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('weight-slider-p1')), findsOneWidget);
    },
  );

  test('CSV parser supports headers, optional email, quotes, and CRLF', () {
    final managers = parseManagerCsv(
      'email,name\r\nnick@example.com,"Coleman, Nick"\r\n,Jordan Smith\r\n',
    );
    expect(managers, [
      (name: 'Coleman, Nick', email: 'nick@example.com'),
      (name: 'Jordan Smith', email: null),
    ]);
  });

  testWidgets('start shows a confirmation sheet before navigating', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = await _storageWithManagers(mode: DraftMode.cards);
    await tester.pumpWidget(_setupHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('FLIP THE CARDS 🎴'));
    await tester.pumpAndSettle();

    expect(find.text('READY TO DRAFT?'), findsOneWidget);
    expect(find.text("LET'S GO"), findsOneWidget);

    // BACK closes the sheet and stays on the setup screen.
    await tester.tap(find.text('BACK'));
    await tester.pumpAndSettle();
    expect(find.text('READY TO DRAFT?'), findsNothing);
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.byType(CardsScreen), findsNothing);

    // LET'S GO proceeds to the reveal screen.
    await tester.tap(find.text('FLIP THE CARDS 🎴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("LET'S GO"));
    await tester.pumpAndSettle();

    expect(find.byType(CardsScreen), findsOneWidget);
  });

  testWidgets('setup sheets do not overflow on a 320x568 screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = await _storageWithManagers(mode: DraftMode.lottery);
    await tester.pumpWidget(_setupHarness(storage));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Pre-draft confirmation sheet.
    await tester.tap(find.text('START THE DRAW 🎱'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('READY TO DRAFT?'), findsOneWidget);
    await tester.tap(find.text('BACK'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Mode detail sheet.
    await tester.tap(find.byIcon(Icons.info_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(ValueKey('mode-detail-${DraftMode.values.first.name}')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Commissioner sheet. Scrolling lays out more of the base screen, so keep
    // the base-screen layout assertion strict before opening the sheet.
    await _dragUntilHitTestable(tester, find.text('🔒 COMMISH'), maxDrags: 30);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('🔒 COMMISH'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('🔒 COMMISSIONER'), findsOneWidget);
  });
}

Future<void> _dragUntilHitTestable(
  WidgetTester tester,
  Finder finder, {
  int maxDrags = 10,
}) async {
  for (
    var i = 0;
    i < maxDrags && finder.hitTestable().evaluate().isEmpty;
    i++
  ) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
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

Future<StorageService> _storageWithManagers({
  int count = 3,
  DraftMode mode = DraftMode.race,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  await storage.saveConfig(
    DraftConfig(
      participants: [
        for (var i = 0; i < count; i++)
          Participant(
            id: 'p${i + 1}',
            name: 'Manager ${i + 1}',
            initials: Participant.initialsForName('Manager ${i + 1}'),
            colorValue: kJerseyPalette[i % kJerseyPalette.length],
          ),
      ],
      mode: mode,
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
