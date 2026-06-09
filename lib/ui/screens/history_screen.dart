import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../domain/draft/draft_mode.dart';
import '../../domain/draft/draft_recap.dart';
import '../../domain/draft/draft_result.dart';
import '../../domain/draft/participant.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/confirm_destructive_action.dart';
import '../widgets/jersey_chip.dart';
import '../widgets/top_picks_podium.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _modeEmoji = {
    DraftMode.race: '🏟️',
    DraftMode.cards: '🎴',
    DraftMode.lottery: '🎱',
    DraftMode.bidding: '💰',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: tk.background,
      appBar: AppBar(
        backgroundColor: tk.background,
        title: Text('HISTORY', style: tk.displayLarge.copyWith(fontSize: 24)),
        actions: [
          if (history.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await confirmDestructiveAction(
                  context,
                  title: 'Clear draft history?',
                  message:
                      'This removes every saved draft board from this device. '
                      'Your current league setup stays intact.',
                  confirmLabel: 'Clear history',
                );
                if (!confirmed || !context.mounted) return;
                await ref.read(historyProvider.notifier).clearAll();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Draft history cleared')),
                );
              },
              child: Text('Clear', style: TextStyle(color: tk.textMuted)),
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏈', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    'No drafts yet',
                    style: tk.title.copyWith(color: tk.textMuted),
                  ),
                  Text(
                    'Run a draft and save the board.',
                    style: tk.body.copyWith(color: tk.textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: history.length,
              itemBuilder: (_, i) {
                final r = history[i];
                final ordered = r.resolve(const []);
                final boardReady =
                    r.order.isNotEmpty && ordered.length == r.order.length;
                final champ = boardReady ? ordered.first : null;
                final d = r.createdAt;
                final date =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                Future<void> copyRecap() async {
                  if (!boardReady) return;
                  final shortRecap = DraftRecap.formatShort(
                    mode: r.mode,
                    ordered: ordered,
                    leagueName: r.leagueName,
                  );
                  final fullRecap = DraftRecap.formatFull(
                    mode: r.mode,
                    ordered: ordered,
                    leagueName: r.leagueName,
                    proofCode: r.proofCode,
                    proofMetadata: r.proofMetadata,
                  );
                  await _showRecapPreviewSheet(
                    context,
                    shortRecap: shortRecap,
                    fullRecap: fullRecap,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _SavedDraftDetailScreen(result: r),
                          ),
                        );
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tk.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tk.scoreboardLine),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _modeEmoji[r.mode] ?? '🏈',
                              style: const TextStyle(fontSize: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.leagueName ?? 'Draft',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tk.title.copyWith(fontSize: 16),
                                  ),
                                  Text(
                                    '${r.mode.label} · $date · ${r.size} mgrs · ${r.proofCode}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tk.body.copyWith(
                                      fontSize: 12,
                                      color: tk.textMuted,
                                    ),
                                  ),
                                  if (!boardReady && r.order.isNotEmpty)
                                    Text(
                                      'Manager details unavailable',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tk.body.copyWith(
                                        fontSize: 11,
                                        color: tk.whistle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (champ != null)
                              SizedBox(
                                width: 88,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      champ.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tk.body.copyWith(
                                        fontSize: 12,
                                        color: tk.gold,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'pick 1',
                                      style: tk.body.copyWith(
                                        fontSize: 10,
                                        color: tk.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (r.order.isNotEmpty)
                              Text(
                                'pick 1',
                                style: tk.body.copyWith(
                                  fontSize: 10,
                                  color: tk.textMuted,
                                ),
                              ),
                            if (boardReady) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Copy recap',
                                icon: Icon(
                                  Icons.copy_rounded,
                                  color: tk.textMuted,
                                ),
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: copyRecap,
                              ),
                            ] else ...[
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: tk.textMuted),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SavedDraftDetailScreen extends StatelessWidget {
  final DraftResult result;
  const _SavedDraftDetailScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final ordered = result.resolve(const []);
    final boardReady =
        result.order.isNotEmpty && ordered.length == result.order.length;
    final d = result.createdAt;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    Future<void> copyRecap() async {
      if (!boardReady) return;
      final shortRecap = DraftRecap.formatShort(
        mode: result.mode,
        ordered: ordered,
        leagueName: result.leagueName,
      );
      final fullRecap = DraftRecap.formatFull(
        mode: result.mode,
        ordered: ordered,
        leagueName: result.leagueName,
        proofCode: result.proofCode,
        proofMetadata: result.proofMetadata,
      );
      await _showRecapPreviewSheet(
        context,
        shortRecap: shortRecap,
        fullRecap: fullRecap,
      );
    }

    return Scaffold(
      backgroundColor: tk.background,
      appBar: AppBar(
        backgroundColor: tk.background,
        title: Text(
          'SAVED BOARD',
          style: tk.displayLarge.copyWith(fontSize: 24),
        ),
      ),
      body: boardReady
          ? ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _SavedBoardHero(
                  result: result,
                  champ: ordered.first,
                  date: date,
                  onWhatThisProves: () => _showProofExplainerDialog(
                    context,
                    proofCode: result.proofCode,
                    proofMetadata: result.proofMetadata,
                  ),
                ),
                const SizedBox(height: 14),
                GhostButton(
                  'COPY RECAP',
                  icon: Icons.copy_rounded,
                  onPressed: copyRecap,
                ),
                if (ordered.length >= 3) ...[
                  const SizedBox(height: 14),
                  TopPicksPodium(ordered: ordered),
                ],
                const SizedBox(height: 18),
                Text(
                  'FULL DRAFT BOARD',
                  style: tk.label.copyWith(color: tk.gold, letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < ordered.length; i++)
                  _SavedPickRow(index: i, participant: ordered[i]),
              ],
            )
          : _MissingBoardDetails(resultProofCode: result.proofCode),
    );
  }
}

class _SavedBoardHero extends StatelessWidget {
  final DraftResult result;
  final Participant champ;
  final String date;
  final VoidCallback onWhatThisProves;

  const _SavedBoardHero({
    required this.result,
    required this.champ,
    required this.date,
    required this.onWhatThisProves,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [tk.scoreboard, tk.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: tk.scoreboardLine),
        boxShadow: [
          BoxShadow(
            color: tk.gold.withValues(alpha: .12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                result.leagueName ?? 'Draft',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tk.displayLarge.copyWith(fontSize: 24),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'What this proves',
                onPressed: onWhatThisProves,
                icon: Icon(Icons.help_outline_rounded, color: tk.textMuted),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                result.proofCode,
                style: tk.mono.copyWith(fontSize: 12, color: tk.led),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${result.mode.label} · $date · ${result.size} managers',
            style: tk.body.copyWith(fontSize: 13, color: tk.textMuted),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tk.gold.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tk.gold.withValues(alpha: .45)),
            ),
            child: Row(
              children: [
                JerseyChip(
                  color: Color(champ.colorValue),
                  number: champ.number,
                  size: 54,
                  highlight: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIRST OVERALL',
                        style: tk.label.copyWith(
                          color: tk.gold,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        champ.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tk.title.copyWith(fontSize: 22),
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

Future<void> _showRecapPreviewSheet(
  BuildContext context, {
  required String shortRecap,
  required String fullRecap,
}) async {
  final tk = context.tokens;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tk.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      Future<void> copyAndDismiss(String text, String message) async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!sheetContext.mounted) return;
        Navigator.of(sheetContext).pop();
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Share recap',
                        style: tk.displayLarge.copyWith(fontSize: 22),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(Icons.close_rounded, color: tk.textMuted),
                    ),
                  ],
                ),
                Text(
                  'Preview the text before copying. Short recap is built for sharing, while the full proof recap includes proof metadata for auditability.',
                  style: tk.body.copyWith(color: tk.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _RecapPreviewBlock(
                  label: 'SHORT RECAP',
                  preview: shortRecap,
                  buttonLabel: 'COPY SHORT RECAP',
                  button: GhostButton(
                    'COPY SHORT RECAP',
                    icon: Icons.copy_rounded,
                    height: 48,
                    onPressed: () =>
                        copyAndDismiss(shortRecap, 'Short recap copied'),
                  ),
                ),
                const SizedBox(height: 14),
                _RecapPreviewBlock(
                  label: 'FULL PROOF RECAP',
                  preview: fullRecap,
                  buttonLabel: 'COPY FULL PROOF RECAP',
                  button: PrimaryButton(
                    'COPY FULL PROOF RECAP',
                    icon: Icons.copy_rounded,
                    height: 54,
                    fontSize: 17,
                    onPressed: () =>
                        copyAndDismiss(fullRecap, 'Full proof recap copied'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showProofExplainerDialog(
  BuildContext context, {
  required String proofCode,
  DraftProofMetadata? proofMetadata,
}) {
  final tk = context.tokens;
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final lines = DraftRecap.proofExplainerLines(
        proofCode: proofCode,
        proofMetadata: proofMetadata,
      );
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tk.gold.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(color: tk.gold.withValues(alpha: .35)),
              ),
              child: Icon(Icons.verified_rounded, color: tk.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'What this proves',
                style: tk.title.copyWith(fontSize: 20),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines) ...[
                  Text(
                    line,
                    style: tk.body.copyWith(color: tk.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Close', style: TextStyle(color: tk.textMuted)),
          ),
        ],
      );
    },
  );
}

class _RecapPreviewBlock extends StatelessWidget {
  final String label;
  final String preview;
  final Widget button;
  final String buttonLabel;

  const _RecapPreviewBlock({
    required this.label,
    required this.preview,
    required this.button,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tk.scoreboardLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tk.label.copyWith(color: tk.gold, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tk.scoreboardLine),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                preview,
                style: tk.mono.copyWith(fontSize: 12, color: tk.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(button: true, label: buttonLabel, child: button),
        ],
      ),
    );
  }
}

class _SavedPickRow extends StatelessWidget {
  final int index;
  final Participant participant;

  const _SavedPickRow({required this.index, required this.participant});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final first = index == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: first ? tk.gold.withValues(alpha: .10) : tk.surface,
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
          JerseyChip(
            color: Color(participant.colorValue),
            number: participant.number,
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              participant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tk.title.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingBoardDetails extends StatelessWidget {
  final String resultProofCode;

  const _MissingBoardDetails({required this.resultProofCode});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Center(
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
                'Saved board details unavailable',
                textAlign: TextAlign.center,
                style: tk.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'The saved pick order exists, but manager details are missing. '
                'Newly saved boards include a full roster snapshot.',
                textAlign: TextAlign.center,
                style: tk.body.copyWith(color: tk.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Text(
                resultProofCode,
                style: tk.mono.copyWith(fontSize: 12, color: tk.led),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
