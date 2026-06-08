// Dev-only entrypoint to preview a single screen with a seeded league, so
// screens can be screenshotted without manual navigation.
//   flutter run -t lib/preview.dart --dart-define=PREVIEW=race
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progenitor_core/progenitor_core.dart';

import 'domain/draft/draft_mode.dart';
import 'storage/storage_service.dart';
import 'ui/screens/bidding_screen.dart';
import 'ui/screens/cards_screen.dart';
import 'ui/screens/lottery_screen.dart';
import 'ui/screens/race_screen.dart';
import 'ui/screens/result_screen.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/state/providers.dart';
import 'ui/theme/app_tokens.dart';

const _which = String.fromEnvironment('PREVIEW', defaultValue: 'race');

Future<void> main() => ProgenitorBootstrap.runWithStorage<StorageService>(
  sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
  openStorage: StorageService.open,
  app: (s) => ProviderScope(
    overrides: [storageProvider.overrideWithValue(s)],
    child: const _PreviewApp(),
  ),
);

class _PreviewApp extends ConsumerStatefulWidget {
  const _PreviewApp();
  @override
  ConsumerState<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends ConsumerState<_PreviewApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seed());
  }

  void _seed() {
    final c = ref.read(draftConfigProvider.notifier);
    c.clearLeague();
    for (final n in const [
      'Coleman',
      'Dana',
      'Marcus',
      'Priya',
      'Sam',
      'Riley',
      'Alex',
      'Jordan',
    ]) {
      c.addManager(n);
    }
    final ps = ref.read(draftConfigProvider).participants;
    c.setWeight(ps[0].id, 0.5);
    c.setWeight(ps[1].id, 3.0);
    ref.read(leagueNameProvider.notifier).set("The League '26");

    final mode = switch (_which) {
      'cards' => DraftMode.cards,
      'lottery' => DraftMode.lottery,
      'bidding' => DraftMode.bidding,
      _ => DraftMode.race,
    };
    c.setMode(mode);

    if (_which == 'bidding') {
      ref.read(auctionProvider.notifier).start();
    } else if (_which != 'setup') {
      ref.read(draftControllerProvider.notifier).run();
    }
    setState(() => _ready = true);
  }

  Widget _screen() => switch (_which) {
    'setup' => const SetupScreen(),
    'cards' => const CardsScreen(),
    'lottery' => const LotteryScreen(),
    'bidding' => const BiddingScreen(),
    'result' => const ResultScreen(),
    _ => const RaceScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return AppThemeScope<DraftTokens>(
      theme: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _ready ? _screen() : const ColoredBox(color: Color(0xFF0B0F14)),
      ),
    );
  }
}
