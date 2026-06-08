import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/league_ledger.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/confirm_destructive_action.dart';
import '../widgets/jersey_chip.dart';

class LeagueLedgerScreen extends ConsumerWidget {
  const LeagueLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final cfg = ref.watch(draftConfigProvider);
    final entries = cfg.ledgerEntries;
    final byId = {for (final p in cfg.participants) p.id: p};

    return Scaffold(
      backgroundColor: tk.background,
      appBar: AppBar(
        backgroundColor: tk.background,
        title: Text(
          'LEAGUE LEDGER',
          style: tk.displayLarge.copyWith(fontSize: 24),
        ),
        actions: [
          if (entries.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await confirmDestructiveAction(
                  context,
                  title: 'Clear League Ledger?',
                  message:
                      'This removes every season-long note, penalty, boost, '
                      'and pick lock from this league.',
                  confirmLabel: 'Clear ledger',
                );
                if (!confirmed || !context.mounted) return;
                ref.read(draftConfigProvider.notifier).clearLedger();
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Track the receipts: punishments, rewards, traded picks, and '
            'commissioner notes that should matter on draft day.',
            style: tk.body.copyWith(color: tk.textMuted),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'ADD LEDGER ENTRY',
            icon: Icons.add_rounded,
            onPressed: cfg.participants.isEmpty
                ? null
                : () => _showEntrySheet(context, ref),
          ),
          const SizedBox(height: 16),
          if (cfg.participants.isEmpty)
            _EmptyState(
              title: 'No managers yet',
              message: 'Add managers before creating ledger entries.',
              tk: tk,
            )
          else if (entries.isEmpty)
            _EmptyState(
              title: 'Ledger is clean',
              message:
                  'Add season consequences now and they will be summarized on '
                  'draft day.',
              tk: tk,
            )
          else
            for (final entry in entries)
              _LedgerCard(
                entry: entry,
                managerName: byId[entry.managerId]?.name,
              ),
        ],
      ),
    );
  }

  void _showEntrySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _LedgerEntrySheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final DraftTokens tk;

  const _EmptyState({
    required this.title,
    required this.message,
    required this.tk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tk.scoreboardLine),
      ),
      child: Column(
        children: [
          Text(title, style: tk.title.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: tk.body.copyWith(color: tk.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LedgerCard extends ConsumerWidget {
  final LeagueLedgerEntry entry;
  final String? managerName;

  const _LedgerCard({required this.entry, required this.managerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final accent = switch (entry.type) {
      LedgerEntryType.oddsBoost => tk.success,
      LedgerEntryType.oddsPenalty => tk.whistle,
      LedgerEntryType.pickLock => tk.gold,
      LedgerEntryType.note => tk.ice,
    };
    final effect = switch (entry.type) {
      LedgerEntryType.oddsBoost =>
        '+${entry.weightDelta.abs().toStringAsFixed(1)}x odds',
      LedgerEntryType.oddsPenalty =>
        '-${entry.weightDelta.abs().toStringAsFixed(1)}x odds',
      LedgerEntryType.pickLock => 'pick #${(entry.pickIndex ?? 0) + 1}',
      LedgerEntryType.note => 'note',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tk.scoreboardLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: .16),
              border: Border.all(color: accent),
            ),
            child: Icon(_iconFor(entry.type), color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: tk.title.copyWith(fontSize: 17)),
                const SizedBox(height: 4),
                Text(
                  '${managerName ?? "Unknown manager"} · $effect',
                  style: tk.label.copyWith(fontSize: 11, color: accent),
                ),
                if (entry.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.notes,
                    style: tk.body.copyWith(fontSize: 12, color: tk.textMuted),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: tk.textMuted),
            onPressed: () => ref
                .read(draftConfigProvider.notifier)
                .removeLedgerEntry(entry.id),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(LedgerEntryType type) => switch (type) {
    LedgerEntryType.oddsBoost => Icons.trending_up_rounded,
    LedgerEntryType.oddsPenalty => Icons.trending_down_rounded,
    LedgerEntryType.pickLock => Icons.push_pin_rounded,
    LedgerEntryType.note => Icons.sticky_note_2_rounded,
  };
}

class _LedgerEntrySheet extends ConsumerStatefulWidget {
  const _LedgerEntrySheet();

  @override
  ConsumerState<_LedgerEntrySheet> createState() => _LedgerEntrySheetState();
}

class _LedgerEntrySheetState extends ConsumerState<_LedgerEntrySheet> {
  late String _managerId;
  LedgerEntryType _type = LedgerEntryType.oddsPenalty;
  double _magnitude = .5;
  int _pickIndex = 0;
  final _title = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final managers = ref.read(draftConfigProvider).participants;
    _managerId = managers.isEmpty ? '' : managers.first.id;
    _title.text = 'Season consequence';
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final cfg = ref.watch(draftConfigProvider);
    final managers = cfg.participants;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'ADD TO LEAGUE LEDGER',
              style: tk.displayLarge.copyWith(fontSize: 24, color: tk.gold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _managerId,
              dropdownColor: tk.surface,
              decoration: const InputDecoration(labelText: 'Manager'),
              items: [
                for (final p in managers)
                  DropdownMenuItem(
                    value: p.id,
                    child: Row(
                      children: [
                        JerseyChip(
                          color: Color(p.colorValue),
                          number: p.number,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(p.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _managerId = v ?? _managerId),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<LedgerEntryType>(
              initialValue: _type,
              dropdownColor: tk.surface,
              decoration: const InputDecoration(labelText: 'Entry type'),
              items: [
                for (final type in LedgerEntryType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              style: tk.body,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              style: tk.body,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 12),
            if (_type == LedgerEntryType.oddsBoost ||
                _type == LedgerEntryType.oddsPenalty) ...[
              Text(
                '${_type == LedgerEntryType.oddsBoost ? "Boost" : "Penalty"}: ${_magnitude.toStringAsFixed(1)}x odds',
                style: tk.label.copyWith(color: tk.gold),
              ),
              Slider(
                value: _magnitude,
                min: .1,
                max: 3,
                divisions: 29,
                activeColor: tk.gold,
                inactiveColor: tk.scoreboardLine,
                onChanged: (v) => setState(() => _magnitude = v),
              ),
            ] else if (_type == LedgerEntryType.pickLock) ...[
              Text(
                'Lock to pick #${_pickIndex + 1}',
                style: tk.label.copyWith(color: tk.gold),
              ),
              Slider(
                value: _pickIndex.toDouble(),
                min: 0,
                max: (managers.length - 1).toDouble(),
                divisions: managers.length > 1 ? managers.length - 1 : null,
                activeColor: tk.gold,
                inactiveColor: tk.scoreboardLine,
                onChanged: (v) => setState(() => _pickIndex = v.round()),
              ),
            ],
            const SizedBox(height: 14),
            PrimaryButton('SAVE ENTRY', onPressed: _save),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _title.text.trim();
    final entry = LeagueLedgerEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      managerId: _managerId,
      title: title.isEmpty ? _type.label : title,
      notes: _notes.text.trim(),
      weightDelta: switch (_type) {
        LedgerEntryType.oddsBoost => _magnitude,
        LedgerEntryType.oddsPenalty => -_magnitude,
        _ => 0,
      },
      pickIndex: _type == LedgerEntryType.pickLock ? _pickIndex : null,
      createdAt: DateTime.now(),
    );
    ref.read(draftConfigProvider.notifier).addLedgerEntry(entry);
    Navigator.pop(context);
  }
}
