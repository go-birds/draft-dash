import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../domain/draft/participant.dart';
import '../../domain/draft/draft_recap.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/jersey_chip.dart';
import '../widgets/top_picks_podium.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final result = ref.watch(draftControllerProvider);
    final cfg = ref.watch(draftConfigProvider);

    if (result == null || result.order.isEmpty) {
      return Scaffold(
        backgroundColor: tk.background,
        body: Center(
          child: Text(
            'No draft yet',
            style: tk.body.copyWith(color: tk.textMuted),
          ),
        ),
      );
    }

    final ordered = result.resolve(cfg.participants);
    if (ordered.length != result.order.length) {
      return _UnavailableResult(resultProofCode: result.proofCode);
    }
    final champ = ordered.first;

    void reorder(int oldIndex, int newIndex) {
      final ids = [...result.order];
      if (newIndex > oldIndex) newIndex -= 1;
      final item = ids.removeAt(oldIndex);
      ids.insert(newIndex, item);
      ref.read(draftControllerProvider.notifier).editOrder(ids);
    }

    Future<void> copyRecap() async {
      final recap = DraftRecap.format(
        mode: result.mode,
        ordered: ordered,
        leagueName: ref.read(leagueNameProvider),
        proofCode: result.proofCode,
        proofMetadata: result.proofMetadata,
      );
      await Clipboard.setData(ClipboardData(text: recap));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft recap copied')));
    }

    return Scaffold(
      backgroundColor: tk.background,
      body: Column(
        children: [
          _ChampBanner(champ: champ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
            child: Row(
              children: [
                Text(
                  'DRAFT BOARD',
                  style: tk.displayLarge.copyWith(fontSize: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tk.gold),
                  ),
                  child: Text(
                    '✎ COMMISH EDIT',
                    style: tk.label.copyWith(color: tk.gold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'DRAG ANY ROW TO OVERRIDE THE ORDER',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tk.label.copyWith(fontSize: 10, color: tk.textMuted),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  result.proofCode,
                  style: tk.mono.copyWith(fontSize: 11, color: tk.led),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              header: ordered.length >= 3
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
                      child: TopPicksPodium(ordered: ordered),
                    )
                  : null,
              itemCount: ordered.length,
              onReorder: reorder,
              proxyDecorator: (child, index, anim) =>
                  Material(color: Colors.transparent, child: child),
              itemBuilder: (_, i) => _PickRow(
                key: ValueKey(ordered[i].id),
                index: i,
                p: ordered[i],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GhostButton(
                          'RUN AGAIN',
                          icon: Icons.replay_rounded,
                          height: 48,
                          onPressed: () {
                            Navigator.of(context)
                              ..pop()
                              ..pop(); // back to setup
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GhostButton(
                          'COPY RECAP',
                          icon: Icons.copy_rounded,
                          height: 48,
                          onPressed: copyRecap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    'SAVE BOARD',
                    icon: Icons.emoji_events_rounded,
                    onPressed: () async {
                      await ref
                          .read(draftControllerProvider.notifier)
                          .saveToHistory();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Draft saved to history')),
                      );
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableResult extends StatelessWidget {
  final String resultProofCode;
  const _UnavailableResult({required this.resultProofCode});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Scaffold(
      backgroundColor: tk.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: tk.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: tk.scoreboardLine),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_late_rounded, color: tk.gold, size: 42),
                  const SizedBox(height: 14),
                  Text(
                    'Draft details unavailable',
                    textAlign: TextAlign.center,
                    style: tk.title.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The pick order exists, but manager details are missing. '
                    'Start a fresh draft to rebuild the board.',
                    textAlign: TextAlign.center,
                    style: tk.body.copyWith(color: tk.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    resultProofCode,
                    style: tk.mono.copyWith(fontSize: 12, color: tk.led),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    'BACK TO SETUP',
                    height: 50,
                    fontSize: 17,
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChampBanner extends StatelessWidget {
  final Participant champ;
  const _ChampBanner({required this.champ});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return SizedBox(
      height: 226,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tk.endZone, tk.endZoneDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                tileMode: TileMode.repeated,
                stops: const [.5, .5],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -1),
                radius: 1.1,
                colors: [Color(0x55F5A524), Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🏆 FIRST OVERALL PICK',
                  style: tk.label.copyWith(color: tk.gold, letterSpacing: 3),
                ),
                const SizedBox(height: 10),
                JerseyChip(
                  color: Color(champ.colorValue),
                  number: champ.number,
                  size: 66,
                  highlight: true,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    champ.name.toUpperCase(),
                    style: tk.displayLarge.copyWith(fontSize: 34),
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

class _PickRow extends StatelessWidget {
  final int index;
  final Participant p;
  const _PickRow({super.key, required this.index, required this.p});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final first = index == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: first ? tk.gold : tk.scoreboardLine),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: tk.displayLarge.copyWith(
                fontSize: 26,
                color: first ? tk.gold : tk.textMuted,
              ),
            ),
          ),
          JerseyChip(color: Color(p.colorValue), number: p.number, size: 42),
          const SizedBox(width: 14),
          Expanded(child: Text(p.name, style: tk.title.copyWith(fontSize: 18))),
          Icon(Icons.drag_handle, color: tk.textMuted),
        ],
      ),
    );
  }
}
