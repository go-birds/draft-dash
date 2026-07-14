import 'package:draft_race/domain/draft/draft_config.dart';
import 'package:draft_race/domain/draft/draft_mode.dart';
import 'package:draft_race/domain/draft/draft_settings.dart';
import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/bidding_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Distinct budgets keep every tie-break (high bid and the no-bid fallback)
/// deterministic, since AuctionController uses an unseeded Random for ties.
const _managers = [
  Participant(
    id: 'p1',
    name: 'Nick',
    number: '07',
    colorValue: 0xFF3A86FF,
    budget: 100,
  ),
  Participant(
    id: 'p2',
    name: 'Jordan',
    number: '23',
    colorValue: 0xFFE63946,
    budget: 80,
  ),
  Participant(
    id: 'p3',
    name: 'Taylor',
    number: '12',
    colorValue: 0xFFFFB703,
    budget: 60,
  ),
];

void main() {
  testWidgets('renders round 1 with pick #1 on the block and manager rows', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));

    expect(find.text('💰 COLEMANBUCKS AUCTION'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.textContaining('ON THE BLOCK'), findsOneWidget);

    // Every manager has an entry row with budget + bid affordance.
    expect(find.text('Nick'), findsOneWidget);
    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('Taylor'), findsOneWidget);
    expect(find.text('💰 100 CB'), findsOneWidget);
    expect(find.text('💰 80 CB'), findsOneWidget);
    expect(find.text('💰 60 CB'), findsOneWidget);
    expect(find.text('TAP TO BID'), findsNWidgets(3));

    // Reveal is gated until everyone has locked a bid.
    expect(find.text('ALL MANAGERS MUST BID (0/3)'), findsOneWidget);
    expect(find.text('REVEAL BIDS 👀'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('one sealed-bid round: high bidder wins and pays their bid', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));

    await _lockBid(tester, 'Nick', 30);
    expect(find.text('BID IN'), findsOneWidget);
    expect(find.text('ALL MANAGERS MUST BID (1/3)'), findsOneWidget);

    await _lockBid(tester, 'Jordan', 20);
    await _pass(tester, 'Taylor');
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('REVEAL BIDS 👀'));
    await tester.pumpAndSettle();

    // Winner banner + deducted budget (100 - 30).
    expect(find.text('SEALED BIDS REVEALED'), findsOneWidget);
    expect(find.text('NICK WINS'), findsOneWidget);
    expect(find.text('paid 30 CB · 70 left'), findsOneWidget);
    expect(find.text('  ★ WINNER'), findsOneWidget);
    expect(find.text('passed'), findsOneWidget); // Taylor's 0 bid

    final auction = container.read(auctionProvider)!;
    expect(auction.assignedPicks, ['p1']);
    expect(auction.budgetOf('p1'), 70);
    expect(auction.budgetOf('p2'), 80); // losers keep their bucks
    expect(auction.budgetOf('p3'), 60);

    // Advance to the next round: winner is off the block.
    await tester.tap(find.text('AWARD & BID PICK #2 ›'));
    await tester.pumpAndSettle();

    expect(find.text('#2'), findsOneWidget);
    expect(find.text('Nick'), findsNothing);
    expect(find.text('TAP TO BID'), findsNWidgets(2));
    expect(find.text('ALL MANAGERS MUST BID (0/2)'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'completing every round sets the draft result and shows the board',
    (tester) async {
      final container = await _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_harness(container));

      // Round 1: Nick outbids everyone.
      await _lockBid(tester, 'Nick', 30);
      await _lockBid(tester, 'Jordan', 20);
      await _pass(tester, 'Taylor');
      await tester.tap(find.text('REVEAL BIDS 👀'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AWARD & BID PICK #2 ›'));
      await tester.pumpAndSettle();

      // Round 2: Jordan beats Taylor.
      await _lockBid(tester, 'Jordan', 10);
      await _pass(tester, 'Taylor');
      await tester.tap(find.text('REVEAL BIDS 👀'));
      await tester.pumpAndSettle();
      expect(container.read(draftControllerProvider), isNull);
      await tester.tap(find.text('AWARD & BID PICK #3 ›'));
      await tester.pumpAndSettle();

      // Round 3: Taylor is the only manager left.
      await _lockBid(tester, 'Taylor', 5);
      await tester.tap(find.text('REVEAL BIDS 👀'));
      await tester.pumpAndSettle();

      // Auction complete: the controller hands the order to the draft result.
      final auction = container.read(auctionProvider)!;
      expect(auction.isComplete, isTrue);
      expect(auction.budgetOf('p3'), 55); // 60 - 5

      final result = container.read(draftControllerProvider);
      expect(result, isNotNull);
      expect(result!.order, ['p1', 'p2', 'p3']);
      expect(result.mode, DraftMode.bidding);
      expect(result.rosterSnapshot, _managers);
      expect(result.proofMetadata, isNotNull);

      // Final reveal navigates to the result board.
      expect(find.text('SEE THE BOARD ✓'), findsOneWidget);
      await tester.tap(find.text('SEE THE BOARD ✓'));
      await tester.pumpAndSettle();

      expect(find.text('🏆 FIRST OVERALL PICK'), findsOneWidget);
      expect(find.text('NICK'), findsOneWidget); // champ banner
      expect(find.text('DRAFT BOARD'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('no-bid round awards the pick to the highest budget for free', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));

    await _pass(tester, 'Nick');
    await _pass(tester, 'Jordan');
    await _pass(tester, 'Taylor');

    await tester.tap(find.text('REVEAL BIDS 👀'));
    await tester.pumpAndSettle();

    // AuctionState.resolveRound fallback: highest remaining budget (Nick,
    // 100 CB) takes the pick and pays nothing.
    expect(find.text('NICK WINS'), findsOneWidget);
    expect(find.text('paid 0 CB · 100 left'), findsOneWidget);
    expect(find.text('passed'), findsNWidgets(3));
    expect(find.text('—'), findsNWidgets(3));

    final auction = container.read(auctionProvider)!;
    expect(auction.assignedPicks, ['p1']);
    expect(auction.budgetOf('p1'), 100); // free pick — nothing deducted

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an empty state when no auction is running', (
    tester,
  ) async {
    final container = await _container(startAuction: false);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));

    expect(find.text('No auction'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

// ─── harness ─────────────────────────────────────────────────────────────

Future<ProviderContainer> _container({bool startAuction = true}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  // Mute SFX/haptics so AppFeedback stays a no-op under test.
  await storage.saveSettings(
    const DraftSettings(soundEnabled: false, hapticsEnabled: false),
  );
  await storage.saveConfig(
    const DraftConfig(participants: _managers, mode: DraftMode.bidding),
  );

  final container = ProviderContainer(
    overrides: [storageProvider.overrideWithValue(storage)],
  );
  if (startAuction) {
    // Same wiring the app uses when entering bidding mode.
    container.read(auctionProvider.notifier).start();
  }
  return container;
}

Widget _harness(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: const MaterialApp(home: BiddingScreen()),
  ),
);

/// Opens [name]'s bid sheet, steps the amount up, and locks it in.
Future<void> _lockBid(WidgetTester tester, String name, int amount) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle(); // sheet slide-in

  for (var i = 0; i < amount ~/ 10; i++) {
    await tester.tap(find.text('+10'));
    await tester.pump();
  }
  for (var i = 0; i < amount % 10; i++) {
    await tester.tap(find.text('+1'));
    await tester.pump();
  }
  expect(find.text('$amount'), findsWidgets); // big gold readout

  await tester.tap(find.text('LOCK IN BID 🔒'));
  await tester.pumpAndSettle(); // sheet dismiss
}

/// Opens [name]'s bid sheet and passes (locks a 0 bid).
Future<void> _pass(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text('PASS (0)'));
  await tester.pumpAndSettle();
}
