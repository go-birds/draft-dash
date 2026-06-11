import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../domain/draft/participant.dart';
import '../../domain/draft/draft_recap.dart';
import '../../domain/draft/draft_result.dart';
import '../../services/feedback.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/jersey_chip.dart';
import '../widgets/top_picks_podium.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  /// Set on the first build that shows a valid board, so commissioner
  /// reorders/rebuilds don't replay the celebration cue.
  bool _celebrated = false;

  @override
  Widget build(BuildContext context) {
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

    if (!_celebrated) {
      _celebrated = true;
      // Haptic + SFX paired with the confetti burst; AppFeedback gates both
      // on the user's sound/haptics settings.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppFeedback.of(ref).award();
      });
    }

    void reorder(int oldIndex, int newIndex) {
      final ids = [...result.order];
      if (newIndex > oldIndex) newIndex -= 1;
      final item = ids.removeAt(oldIndex);
      ids.insert(newIndex, item);
      ref.read(draftControllerProvider.notifier).editOrder(ids);
    }

    Future<void> showRecapPreview() async {
      final shortRecap = DraftRecap.formatShort(
        mode: result.mode,
        ordered: ordered,
        leagueName: ref.read(leagueNameProvider),
        proofCode: result.proofCode,
      );
      final fullRecap = DraftRecap.formatFull(
        mode: result.mode,
        ordered: ordered,
        leagueName: ref.read(leagueNameProvider),
        proofCode: result.proofCode,
        proofMetadata: result.proofMetadata,
      );
      await _showRecapPreviewSheet(
        context,
        shortRecap: shortRecap,
        fullRecap: fullRecap,
      );
    }

    void showProofExplainer() {
      _showProofExplainerDialog(
        context,
        proofCode: result.proofCode,
        proofMetadata: result.proofMetadata,
      );
    }

    Future<void> copyProofCode() async {
      await Clipboard.setData(ClipboardData(text: result.proofCode));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proof code copied')));
    }

    return Scaffold(
      backgroundColor: tk.background,
      body: Column(
        children: [
          Stack(
            children: [
              _ChampBanner(champ: champ),
              const Positioned.fill(child: ConfettiOverlay()),
            ],
          ),
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
                IconButton(
                  tooltip: 'What this proves',
                  onPressed: showProofExplainer,
                  icon: Icon(Icons.help_outline_rounded, color: tk.textMuted),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: 'Copy proof code ${result.proofCode}',
                  child: InkWell(
                    onTap: copyProofCode,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            result.proofCode,
                            style: tk.mono.copyWith(
                              fontSize: 11,
                              color: tk.led,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: tk.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                last: ordered.length > 1 && i == ordered.length - 1,
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
                          onPressed: showRecapPreview,
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

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
        ),
        child: SafeArea(
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
                    'Preview the text before copying. Short recap is built for sharing, while the full proof recap includes the details needed to verify the result.',
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

      Future<void> copyProofCode() async {
        await Clipboard.setData(ClipboardData(text: proofCode));
        if (!dialogContext.mounted) return;
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(const SnackBar(content: Text('Proof code copied')));
      }

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
                  if (line == 'Proof code: $proofCode')
                    Semantics(
                      button: true,
                      label: 'Copy proof code $proofCode',
                      child: InkWell(
                        onTap: copyProofCode,
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                line,
                                style: tk.body.copyWith(
                                  color: tk.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: tk.textMuted,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      line,
                      style: tk.body.copyWith(
                        color: tk.textMuted,
                        fontSize: 14,
                      ),
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
  final bool last;
  const _PickRow({
    super.key,
    required this.index,
    required this.p,
    this.last = false,
  });

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
          if (last) ...[
            const SizedBox(width: 8),
            // The anti-gold: a deliberately muted chip for the final pick.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tk.textMuted.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tk.textMuted.withValues(alpha: .45)),
              ),
              child: Text(
                'MR. IRRELEVANT',
                style: tk.label.copyWith(
                  fontSize: 9,
                  color: tk.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.drag_handle, color: tk.textMuted),
        ],
      ),
    );
  }
}
