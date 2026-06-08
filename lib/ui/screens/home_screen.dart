import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import 'history_screen.dart';
import 'league_ledger_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final cfg = ref.watch(draftConfigProvider);
    final league = ref.watch(leagueNameProvider);
    final hasLeague = cfg.participants.isNotEmpty;

    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      backgroundColor: tk.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SkyAndTurf()),
          const Positioned(top: 36, left: 28, child: _LightBank()),
          const Positioned(top: 36, right: 28, child: _LightBank()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, tk.background],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Text(
                  'FANTASY FOOTBALL',
                  style: tk.label.copyWith(color: tk.gold, letterSpacing: 5),
                ),
                const SizedBox(height: 6),
                Text(
                  'DRAFT',
                  style: tk.displayLarge.copyWith(
                    fontSize: 76,
                    height: .86,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'RACE',
                  style: tk.displayLarge.copyWith(
                    fontSize: 76,
                    height: .86,
                    letterSpacing: 1,
                    color: tk.gold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'SETTLE IT ON THE FIELD',
                  style: tk.label.copyWith(letterSpacing: 3),
                ),
                const Spacer(flex: 2),
                const Text('🏈', style: TextStyle(fontSize: 92)),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                  child: Column(
                    children: [
                      PrimaryButton(
                        hasLeague ? 'NEW DRAFT' : 'GET STARTED',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          if (hasLeague) {
                            ref
                                .read(draftConfigProvider.notifier)
                                .prepareNewDraft();
                          }
                          open(const SetupScreen());
                        },
                      ),
                      if (hasLeague) ...[
                        const SizedBox(height: 12),
                        GhostButton(
                          '↺  ${league.isEmpty ? "LAST LEAGUE" : league.toUpperCase()}  ·  ${cfg.participants.length} MGRS',
                          onPressed: () => open(const SetupScreen()),
                        ),
                        const SizedBox(height: 12),
                        GhostButton(
                          '📒  LEAGUE LEDGER  ·  ${cfg.ledgerEntries.length} ENTRIES',
                          onPressed: () => open(const LeagueLedgerScreen()),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GhostButton(
                              '🏆  HISTORY',
                              onPressed: () => open(const HistoryScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GhostButton(
                              '⚙  SETTINGS',
                              onPressed: () => open(const SettingsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyAndTurf extends StatelessWidget {
  const _SkyAndTurf();

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1.1),
              radius: 1.3,
              colors: [Color(0xFF14335E), Color(0xFF0A1622), Color(0xFF05070A)],
              stops: [0, .45, 1],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateX(0.95),
            child: Container(
              height: 360,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tk.turf, tk.turfDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  tileMode: TileMode.repeated,
                  stops: const [.5, .5],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < 5; i++)
                    Container(
                      width: 3,
                      color: tk.yardLine.withValues(alpha: .55),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LightBank extends StatelessWidget {
  const _LightBank();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 32,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF27384F), Color(0xFF16222F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB4D2FF).withValues(alpha: .35),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDFEEFF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCFE4FF).withValues(alpha: .9),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
