import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/draft_config.dart';
import '../../domain/draft/draft_mode.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/confirm_destructive_action.dart';
import '../widgets/jersey_chip.dart';
import '../widgets/manager_tile.dart';
import '../widgets/mode_card.dart';
import 'bidding_screen.dart';
import 'cards_screen.dart';
import 'league_ledger_screen.dart';
import 'lottery_screen.dart';
import 'race_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late final TextEditingController _league;

  @override
  void initState() {
    super.initState();
    _league = TextEditingController(text: ref.read(leagueNameProvider));
  }

  @override
  void dispose() {
    _league.dispose();
    super.dispose();
  }

  static const _emoji = {
    DraftMode.race: '🏟️',
    DraftMode.cards: '🎴',
    DraftMode.lottery: '🎱',
    DraftMode.bidding: '💰',
  };

  void _start() {
    final cfg = ref.read(draftConfigProvider);
    if (cfg.participants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 managers to draft.')),
      );
      return;
    }
    ref.read(leagueNameProvider.notifier).set(_league.text.trim());

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.tokens.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => _StartConfirmSheet(
        cfg: cfg,
        onConfirm: () {
          Navigator.pop(sheetCtx);
          _launch(cfg);
        },
      ),
    );
  }

  void _launch(DraftConfig cfg) {
    Widget screen;
    switch (cfg.mode) {
      case DraftMode.race:
        ref.read(draftControllerProvider.notifier).run();
        screen = const RaceScreen();
      case DraftMode.cards:
        ref.read(draftControllerProvider.notifier).run();
        screen = const CardsScreen();
      case DraftMode.lottery:
        ref.read(draftControllerProvider.notifier).run();
        screen = const LotteryScreen();
      case DraftMode.bidding:
        ref.read(auctionProvider.notifier).start();
        screen = const BiddingScreen();
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  String get _ctaLabel => switch (ref.read(draftConfigProvider).mode) {
    DraftMode.race => 'START THE RACE 🏈',
    DraftMode.cards => 'FLIP THE CARDS 🎴',
    DraftMode.lottery => 'START THE DRAW 🎱',
    DraftMode.bidding => 'START THE AUCTION 💰',
  };

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final cfg = ref.watch(draftConfigProvider);
    final ctrl = ref.read(draftConfigProvider.notifier);
    final pinned = cfg.pins.isNotEmpty;

    return Scaffold(
      backgroundColor: tk.background,
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: tk.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _league,
                      style: tk.displayLarge.copyWith(fontSize: 24),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'LEAGUE NAME',
                        hintStyle: tk.displayLarge.copyWith(
                          fontSize: 24,
                          color: tk.textMuted,
                        ),
                      ),
                      onChanged: (v) =>
                          ref.read(leagueNameProvider.notifier).set(v.trim()),
                    ),
                  ),
                  Text(
                    '${cfg.participants.length} MGRS',
                    style: tk.label.copyWith(color: tk.textMuted),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  _panel(
                    tk,
                    title: 'FORMAT',
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.88,
                      children: [
                        for (final m in DraftMode.values)
                          ModeCard(
                            emoji: _emoji[m]!,
                            title: m.label,
                            blurb: m.blurb,
                            bestFor: _modeInfo[m]!.bestFor,
                            selected: cfg.mode == m,
                            onTap: () {
                              ctrl.setMode(m);
                              setState(() {});
                            },
                            onInfoTap: () => _openModeInfo(context, m),
                          ),
                      ],
                    ),
                  ),
                  _panel(
                    tk,
                    title: 'MANAGERS',
                    child: cfg.participants.isEmpty
                        ? _emptyRoster(tk, ctrl)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final p in cfg.participants) ...[
                                ManagerTile(
                                  key: ValueKey(p.id),
                                  p: p,
                                  mode: cfg.mode,
                                  weightingEnabled: cfg.weightingEnabled,
                                ),
                                const SizedBox(height: 10),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: GhostButton(
                                      '＋ ADD MANAGER',
                                      height: 46,
                                      onPressed:
                                          cfg.participants.length >=
                                              DraftConfigController.maxManagers
                                          ? null
                                          : ctrl.addManager,
                                    ),
                                  ),
                                ],
                              ),
                              if (cfg.participants.length >=
                                  DraftConfigController.maxManagers) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'League is full (16 max)',
                                  textAlign: TextAlign.center,
                                  style: tk.body.copyWith(
                                    fontSize: 13,
                                    color: tk.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  _panel(
                    tk,
                    title: 'ODDS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cfg.mode == DraftMode.bidding)
                          Text(
                            'Auction mode uses budgets instead of odds.',
                            style: tk.body.copyWith(
                              fontSize: 13,
                              color: tk.textMuted,
                            ),
                          )
                        else ...[
                          _toggle(
                            tk,
                            '⚖ HANDICAP',
                            cfg.weightingEnabled,
                            (v) => ctrl.setWeightingEnabled(v),
                          ),
                          if (cfg.weightingEnabled) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Set each manager’s multiplier independently. Everyone stays at 1.0× unless you edit them; Draft Dash turns those multipliers into fair draw odds right before the reveal.',
                              style: tk.body.copyWith(
                                fontSize: 12.5,
                                color: tk.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _toggle(
                              tk,
                              '🔁 REVERSE (worst picks first)',
                              cfg.reverseOrder,
                              (v) => ctrl.setReverseOrder(v),
                              full: true,
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: ctrl.resetOdds,
                                child: Text(
                                  'Reset odds to even',
                                  style: tk.body.copyWith(
                                    fontSize: 13,
                                    color: tk.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  _panel(
                    tk,
                    title: 'LOTTERY OPTIONS',
                    child:
                        cfg.mode == DraftMode.lottery &&
                            cfg.participants.length >= 2
                        ? _LotteryDepthControl(
                            pickCount: cfg.effectiveLotteryPickCount,
                            maxPickCount: cfg.participants.length - 1,
                            onChanged: ctrl.setLotteryPickCount,
                          )
                        : Text(
                            cfg.mode == DraftMode.lottery
                                ? 'Add at least 2 managers to adjust lottery depth.'
                                : 'Lottery depth applies when Lottery is selected.',
                            style: tk.body.copyWith(
                              fontSize: 13,
                              color: tk.textMuted,
                            ),
                          ),
                  ),
                  _panel(
                    tk,
                    title: 'COMMISSIONER',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lock exact picks before the draw starts.',
                          style: tk.body.copyWith(
                            fontSize: 13,
                            color: tk.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: GhostButton(
                            pinned
                                ? '🔒 RIGGED (${cfg.pins.length})'
                                : '🔒 COMMISH',
                            height: 46,
                            textColor: tk.gold,
                            onPressed: () => _openCommish(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _panel(
                    tk,
                    title: 'LEAGUE LEDGER',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record penalties, boosts, locks, and notes.',
                          style: tk.body.copyWith(
                            fontSize: 13,
                            color: tk.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GhostButton(
                          '📒 LEAGUE LEDGER (${cfg.ledgerEntries.length})',
                          height: 46,
                          textColor: cfg.ledgerEntries.isEmpty ? null : tk.gold,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LeagueLedgerScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // sticky CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(_ctaLabel, onPressed: _start),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty roster card shown when the league has no managers yet.
  Widget _emptyRoster(DraftTokens tk, DraftConfigController ctrl) => Container(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
    decoration: BoxDecoration(
      color: tk.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: tk.scoreboardLine),
    ),
    child: Column(
      children: [
        const Text('🏈', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          'No managers yet — add your league to get started',
          textAlign: TextAlign.center,
          style: tk.body.copyWith(fontSize: 14, color: tk.textMuted),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            'ADD FIRST MANAGER',
            height: 52,
            fontSize: 18,
            onPressed: ctrl.addManager,
          ),
        ),
      ],
    ),
  );

  Widget _panel(
    DraftTokens tk, {
    required String title,
    required Widget child,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: tk.surfaceElevated,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: tk.scoreboardLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tk.label.copyWith(color: tk.gold)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget _toggle(
    DraftTokens tk,
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool full = false,
  }) {
    final row = Row(
      mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tk.body.copyWith(fontSize: 12.5, color: tk.ice),
          ),
        ),
        const SizedBox(width: 6),
        Transform.scale(
          scale: .8,
          child: Switch(
            value: value,
            activeThumbColor: tk.gold,
            onChanged: (v) {
              onChanged(v);
              setState(() {});
            },
          ),
        ),
      ],
    );
    return full
        ? Padding(padding: const EdgeInsets.only(top: 2), child: row)
        : row;
  }

  void _openCommish(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.tokens.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _CommissionerSheet(),
    );
  }

  void _openModeInfo(BuildContext context, DraftMode mode) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.tokens.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _ModeDetailSheet(mode: mode),
    );
  }
}

/// Pre-draft confirmation: summarizes the setup before the reveal starts.
class _StartConfirmSheet extends StatelessWidget {
  final DraftConfig cfg;
  final VoidCallback onConfirm;

  const _StartConfirmSheet({required this.cfg, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: tk.textMuted,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'READY TO DRAFT?',
              style: tk.displayLarge.copyWith(fontSize: 24, color: tk.gold),
            ),
            const SizedBox(height: 14),
            _row(tk, 'FORMAT', cfg.mode.label),
            _row(tk, 'MANAGERS', '${cfg.participants.length}'),
            _row(tk, 'HANDICAP ODDS', cfg.weightingEnabled ? 'ON' : 'OFF'),
            _row(tk, 'COMMISSIONER PINS', '${cfg.pins.length}'),
            if (cfg.mode == DraftMode.lottery)
              _row(tk, 'LOTTERY PICKS', '${cfg.effectiveLotteryPickCount}'),
            const SizedBox(height: 18),
            PrimaryButton("LET'S GO", onPressed: onConfirm),
            const SizedBox(height: 10),
            GhostButton('BACK', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _row(DraftTokens tk, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: tk.label.copyWith(color: tk.textMuted)),
        ),
        Text(value, style: tk.title.copyWith(fontSize: 15, color: tk.ice)),
      ],
    ),
  );
}

class _LotteryDepthControl extends StatelessWidget {
  final int pickCount;
  final int maxPickCount;
  final ValueChanged<int> onChanged;

  const _LotteryDepthControl({
    required this.pickCount,
    required this.maxPickCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final deterministic = maxPickCount - pickCount;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tk.scoreboardLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🎱 LOTTERY PICKS',
                style: tk.label.copyWith(color: tk.gold, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$pickCount of $maxPickCount',
                style: tk.mono.copyWith(color: tk.led, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            deterministic == 0
                ? 'Default: draw every pick until one manager remains.'
                : 'Draw $pickCount picks, then fill the final $deterministic by the remaining order.',
            style: tk.body.copyWith(fontSize: 12, color: tk.textMuted),
          ),
          Slider(
            value: pickCount.toDouble(),
            min: 0,
            max: maxPickCount.toDouble(),
            divisions: maxPickCount,
            activeColor: tk.gold,
            inactiveColor: tk.scoreboardLine,
            label: '$pickCount lottery picks',
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

/// Pre-draw rigging: assign managers to exact pick slots.
class _CommissionerSheet extends ConsumerWidget {
  const _CommissionerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final cfg = ref.watch(draftConfigProvider);
    final ctrl = ref.read(draftConfigProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      maxChildSize: .92,
      builder: (_, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: tk.textMuted,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Text(
                  '🔒 COMMISSIONER',
                  style: tk.displayLarge.copyWith(fontSize: 24, color: tk.gold),
                ),
                const Spacer(),
                if (cfg.pins.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await confirmDestructiveAction(
                        context,
                        title: 'Clear commissioner locks?',
                        message:
                            'This removes every locked pick and returns the '
                            'draft to a fully random draw.',
                        confirmLabel: 'Clear locks',
                      );
                      if (!confirmed || !context.mounted) return;
                      ctrl.clearAllPins();
                    },
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Lock managers to exact picks before the "random" draw. '
              'Unpinned slots fill in around them.',
              style: tk.body.copyWith(fontSize: 13, color: tk.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: cfg.participants.length,
              itemBuilder: (_, slot) {
                final pinnedId = cfg.pins[slot];
                final pinned = pinnedId == null
                    ? null
                    : cfg.participants
                          .where((p) => p.id == pinnedId)
                          .cast<dynamic>()
                          .firstOrNull;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: tk.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pinned != null ? tk.gold : tk.scoreboardLine,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: Text(
                          '#${slot + 1}',
                          style: tk.displayLarge.copyWith(
                            fontSize: 22,
                            color: tk.gold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: pinned == null
                            ? Text(
                                'Random',
                                style: tk.body.copyWith(color: tk.textMuted),
                              )
                            : Row(
                                children: [
                                  JerseyChip(
                                    color: Color(pinned.colorValue),
                                    number: pinned.number,
                                    size: 34,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      pinned.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tk.title.copyWith(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      TextButton(
                        onPressed: () => _assign(context, ref, slot),
                        child: Text(
                          pinned == null ? 'Assign' : 'Change',
                          style: TextStyle(color: tk.ice),
                        ),
                      ),
                      if (pinned != null)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: tk.textMuted,
                          ),
                          onPressed: () => ctrl.clearPin(slot),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _assign(BuildContext context, WidgetRef ref, int slot) {
    final cfg = ref.read(draftConfigProvider);
    final ctrl = ref.read(draftConfigProvider.notifier);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final tk = ctx.tokens;
        return SimpleDialog(
          backgroundColor: tk.surface,
          title: Text('Pick #${slot + 1} →', style: tk.title),
          children: [
            for (final p in cfg.participants)
              SimpleDialogOption(
                onPressed: () {
                  ctrl.setPin(slot, p.id);
                  Navigator.pop(ctx);
                },
                child: Row(
                  children: [
                    JerseyChip(
                      color: Color(p.colorValue),
                      number: p.number,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Text(p.name, style: tk.body),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ModeDetailSheet extends StatelessWidget {
  final DraftMode mode;

  const _ModeDetailSheet({required this.mode});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final copy = _modeInfo[mode]!;

    return DraggableScrollableSheet(
      key: ValueKey('mode-detail-${mode.name}'),
      expand: false,
      initialChildSize: .72,
      maxChildSize: .94,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: tk.textMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mode.label.toUpperCase(),
            style: tk.displayLarge.copyWith(fontSize: 28, color: tk.gold),
          ),
          const SizedBox(height: 8),
          Text(
            'Best for ${copy.bestFor}.',
            style: tk.title.copyWith(fontSize: 16, color: tk.ice),
          ),
          const SizedBox(height: 14),
          Text(
            copy.summary,
            key: ValueKey('mode-detail-summary-${mode.name}'),
            style: tk.body.copyWith(
              fontSize: 14,
              color: tk.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          for (final bullet in copy.bullets) ...[
            _DetailBullet(text: bullet),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DetailBullet extends StatelessWidget {
  final String text;

  const _DetailBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tk.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tk.scoreboardLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: tk.title.copyWith(color: tk.gold, fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: tk.body.copyWith(
                fontSize: 13,
                color: tk.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeInfo {
  final String bestFor;
  final String summary;
  final List<String> bullets;

  const _ModeInfo({
    required this.bestFor,
    required this.summary,
    required this.bullets,
  });
}

const _modeInfo = {
  DraftMode.race: _ModeInfo(
    bestFor: 'a loud, fast reveal night',
    summary:
        'The locked-in draft order becomes a race animation. Every manager is a runner, and the first one across the finish line gets pick #1.',
    bullets: [
      'Use this when you want the reveal to feel like a finish-line sprint.',
      'The draft order is already set before the animation starts.',
      'Each pick is revealed in sequence until the board is complete.',
    ],
  ),
  DraftMode.cards: _ModeInfo(
    bestFor: 'simple, low-friction reveal sessions',
    summary:
        'Card Flip is the cleanest way to show a draft order: one card, one pick, one reveal at a time.',
    bullets: [
      'This mode is ideal when you want the reveal to stay quick and readable.',
      'The app locks in the draft order before the first card flips.',
      'Every manager gets revealed one at a time in the final draft order.',
    ],
  ),
  DraftMode.lottery: _ModeInfo(
    bestFor: 'NBA-style weighted lottery drama',
    summary:
        'Lottery mode uses the NBA process: 14 balls, 4-ball combinations, and 1,000 assigned combinations after the 11-12-13-14 combination is ignored. Lottery picks are drawn first, then any remaining slots follow the remaining order.',
    bullets: [
      'Each manager gets a share of the 1,000 combinations based on weight when handicap odds are enabled.',
      'The draw pulls 4 balls at a time from 14 balls, just like the NBA-style process.',
      'Repeated winners are skipped during the lottery draw, so top picks stay unique.',
    ],
  ),
  DraftMode.bidding: _ModeInfo(
    bestFor: 'live, strategic ColemanBucks auctions',
    summary:
        'Auction mode sells the draft from pick #1 downward. Managers bid with their remaining budgets, the highest bid wins, and the budget payment carries forward to the next round.',
    bullets: [
      'Each round is a sealed-bid auction for the current pick.',
      'Winning managers pay their winning bid out of their remaining budget.',
      'The draft keeps moving until every pick has been sold.',
    ],
  ),
};
