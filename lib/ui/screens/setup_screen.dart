import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final odds = ref.watch(oddsProvider);
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
                  _sectionLabel(tk, 'PICK YOUR FORMAT'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.32,
                    children: [
                      for (final m in DraftMode.values)
                        ModeCard(
                          emoji: _emoji[m]!,
                          title: m.label,
                          blurb: m.blurb,
                          selected: cfg.mode == m,
                          onTap: () {
                            ctrl.setMode(m);
                            setState(() {});
                          },
                        ),
                    ],
                  ),

                  // options row
                  Row(
                    children: [
                      _sectionLabel(
                        tk,
                        cfg.mode == DraftMode.bidding
                            ? 'MANAGERS & BUDGETS'
                            : 'MANAGERS & ODDS',
                      ),
                      const Spacer(),
                      if (cfg.mode != DraftMode.bidding)
                        _toggle(
                          tk,
                          '⚖ HANDICAP',
                          cfg.weightingEnabled,
                          (v) => ctrl.setWeightingEnabled(v),
                        ),
                    ],
                  ),
                  if (cfg.mode != DraftMode.bidding && cfg.weightingEnabled)
                    _toggle(
                      tk,
                      '🔁 REVERSE (worst picks first)',
                      cfg.reverseOrder,
                      (v) => ctrl.setReverseOrder(v),
                      full: true,
                    ),

                  if (cfg.mode == DraftMode.lottery &&
                      cfg.participants.length >= 2)
                    _LotteryDepthControl(
                      pickCount: cfg.effectiveLotteryPickCount,
                      maxPickCount: cfg.participants.length - 1,
                      onChanged: ctrl.setLotteryPickCount,
                    ),

                  const SizedBox(height: 10),
                  for (final p in cfg.participants)
                    ManagerTile(
                      key: ValueKey(p.id),
                      p: p,
                      mode: cfg.mode,
                      oddsPct: odds[p.id] ?? 0,
                      weightingEnabled: cfg.weightingEnabled,
                    ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: GhostButton(
                          '＋ ADD MANAGER',
                          height: 46,
                          onPressed: ctrl.addManager,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 150,
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
                  if (cfg.weightingEnabled &&
                      cfg.mode != DraftMode.bidding) ...[
                    const SizedBox(height: 12),
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

  Widget _sectionLabel(DraftTokens tk, String s) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 10),
    child: Text(s, style: tk.label.copyWith(color: tk.gold)),
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
        Text(label, style: tk.body.copyWith(fontSize: 12.5, color: tk.ice)),
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
                : 'Draw $pickCount picks, then fill $deterministic deterministically.',
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
                                  Text(
                                    pinned.name,
                                    style: tk.title.copyWith(fontSize: 16),
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
