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

    void startNewDraft() {
      if (hasLeague) {
        ref.read(draftConfigProvider.notifier).prepareNewDraft();
      }
      open(const SetupScreen());
    }

    void editSavedLeague() => open(const SetupScreen());

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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    const SizedBox(height: 6),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'FANTASY FOOTBALL',
                            style: tk.label.copyWith(
                              color: tk.gold,
                              letterSpacing: 5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'DRAFT',
                            style: tk.displayLarge.copyWith(
                              fontSize: 62,
                              height: .86,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'RACE',
                            style: tk.displayLarge.copyWith(
                              fontSize: 62,
                              height: .86,
                              letterSpacing: 1,
                              color: tk.gold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'SETTLE IT ON THE FIELD',
                            style: tk.label.copyWith(letterSpacing: 3),
                          ),
                          const SizedBox(height: 10),
                          const Text('🏈', style: TextStyle(fontSize: 72)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'PRIMARY ACTION',
                      icon: Icons.play_arrow_rounded,
                      children: [
                        Text(
                          hasLeague
                              ? 'Start a fresh draft from the current saved league.'
                              : 'Create your league setup, then come back here to run your first draft.',
                          style: tk.body.copyWith(color: tk.textMuted),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          hasLeague ? 'NEW DRAFT' : 'CREATE LEAGUE',
                          icon: Icons.play_arrow_rounded,
                          onPressed: startNewDraft,
                        ),
                        if (hasLeague) ...[
                          const SizedBox(height: 12),
                          GhostButton(
                            'EDIT SAVED LEAGUE',
                            icon: Icons.edit_rounded,
                            onPressed: editSavedLeague,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'NEW DRAFT starts fresh from this league and clears temporary draft-day tweaks. '
                            'EDIT SAVED LEAGUE lets you adjust the roster, mode, odds, and ledger you already saved.',
                            style: tk.body.copyWith(
                              color: tk.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          Text(
                            'You can still explore History, League Ledger, and Settings while you build the league.',
                            style: tk.body.copyWith(
                              color: tk.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'CURRENT LEAGUE SUMMARY',
                      icon: Icons.sports_score_rounded,
                      children: [
                        if (hasLeague) ...[
                          Text(
                            league.isEmpty
                                ? 'LAST LEAGUE'
                                : league.toUpperCase(),
                            style: tk.title.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SummaryChip(
                                label: '${cfg.participants.length} managers',
                              ),
                              _SummaryChip(label: cfg.mode.label.toUpperCase()),
                              _SummaryChip(
                                label:
                                    '${cfg.ledgerEntries.length} ledger entries',
                              ),
                              _SummaryChip(
                                label: cfg.weightingEnabled
                                    ? 'handicap on'
                                    : 'even odds',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            cfg.reverseOrder
                                ? 'Reverse order is on, so the weighted underdog gets the later pick.'
                                : 'The saved league is ready to edit or draft again.',
                            style: tk.body.copyWith(
                              color: tk.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'No saved league yet',
                            style: tk.title.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Here is the setup path for a first run:',
                            style: tk.body.copyWith(color: tk.textMuted),
                          ),
                          const SizedBox(height: 10),
                          for (final step in const [
                            'Create league',
                            'Add managers',
                            'Choose reveal mode',
                            'Run draft',
                            'Save/share recap',
                          ]) ...[
                            _GuidanceStep(label: step),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'LEAGUE LEDGER',
                      icon: Icons.receipt_long_rounded,
                      children: [
                        Text(
                          hasLeague
                              ? 'Track commissioner notes, pick locks, and season-long consequences before draft day.'
                              : 'Use the ledger to record season notes once your league roster is in place.',
                          style: tk.body.copyWith(color: tk.textMuted),
                        ),
                        const SizedBox(height: 12),
                        GhostButton(
                          'OPEN LEAGUE LEDGER · ${cfg.ledgerEntries.length} ENTRIES',
                          icon: Icons.receipt_long_rounded,
                          onPressed: () => open(const LeagueLedgerScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'HISTORY',
                      icon: Icons.history_rounded,
                      children: [
                        Text(
                          'Saved draft boards live here so you can revisit, copy, or share the recap later.',
                          style: tk.body.copyWith(color: tk.textMuted),
                        ),
                        const SizedBox(height: 12),
                        GhostButton(
                          'OPEN HISTORY',
                          icon: Icons.history_rounded,
                          onPressed: () => open(const HistoryScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'SETTINGS',
                      icon: Icons.settings_rounded,
                      children: [
                        Text(
                          'Tweak the stadium look, game-day feedback, and saved league data from one place.',
                          style: tk.body.copyWith(color: tk.textMuted),
                        ),
                        const SizedBox(height: 12),
                        GhostButton(
                          'OPEN SETTINGS',
                          icon: Icons.settings_rounded,
                          onPressed: () => open(const SettingsScreen()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tk.surface.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tk.scoreboardLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tk.gold),
              const SizedBox(width: 8),
              Text(title, style: tk.label.copyWith(color: tk.gold)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;

  const _SummaryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tk.scoreboardLine),
      ),
      child: Text(
        label,
        style: tk.label.copyWith(
          fontSize: 11,
          color: tk.textPrimary,
          letterSpacing: .6,
        ),
      ),
    );
  }
}

class _GuidanceStep extends StatelessWidget {
  final String label;

  const _GuidanceStep({required this.label});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tk.gold.withValues(alpha: .16),
            border: Border.all(color: tk.gold.withValues(alpha: .7)),
          ),
          child: Text(
            '${_steps.indexOf(label) + 1}',
            style: tk.label.copyWith(color: tk.gold, fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(label, style: tk.body.copyWith(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  static const _steps = <String>[
    'Create league',
    'Add managers',
    'Choose reveal mode',
    'Run draft',
    'Save/share recap',
  ];
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
