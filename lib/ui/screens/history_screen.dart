import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/draft_mode.dart';
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
                  Text('No drafts yet',
                      style: tk.title.copyWith(color: tk.textMuted)),
                  Text('Run a draft and save the board.',
                      style: tk.body.copyWith(color: tk.textMuted, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: history.length,
              itemBuilder: (_, i) {
                final r = history[i];
                final champId = r.order.isNotEmpty ? r.order.first : null;
                final d = r.createdAt;
                final date =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
                      Text(_modeEmoji[r.mode] ?? '🏈',
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.leagueName ?? 'Draft',
                                style: tk.title.copyWith(fontSize: 16)),
                            Text('${r.mode.label} · $date · ${r.size} mgrs',
                                style: tk.body.copyWith(
                                    fontSize: 12, color: tk.textMuted)),
                          ],
                        ),
                      ),
                      if (champId != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('🏆', style: TextStyle(fontSize: tk.body.fontSize)),
                            Text('pick 1',
                                style: tk.body.copyWith(
                                    fontSize: 10, color: tk.textMuted)),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
