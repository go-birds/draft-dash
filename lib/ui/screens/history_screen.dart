import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../domain/draft/draft_mode.dart';
import '../../domain/draft/draft_recap.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';

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
              onPressed: () => ref.read(historyProvider.notifier).clearAll(),
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
                final champ = ordered.isEmpty ? null : ordered.first;
                final d = r.createdAt;
                final date =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                Future<void> copyRecap() async {
                  if (ordered.isEmpty) return;
                  final recap = DraftRecap.format(
                    mode: r.mode,
                    ordered: ordered,
                    leagueName: r.leagueName,
                    proofCode: r.proofCode,
                  );
                  await Clipboard.setData(ClipboardData(text: recap));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Draft recap copied')),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                      if (ordered.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Copy recap',
                          icon: Icon(Icons.copy_rounded, color: tk.textMuted),
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 40,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: copyRecap,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
