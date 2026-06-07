import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/draft_mode.dart';
import '../../domain/draft/participant.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import 'jersey_chip.dart';

/// A roster row: jersey + name, plus odds slider (auto modes) or a ColemanBucks
/// field (bidding mode). Edits flow straight to [draftConfigProvider].
class ManagerTile extends ConsumerWidget {
  final Participant p;
  final DraftMode mode;
  final double oddsPct; // 0..1 chance at pick #1
  final bool weightingEnabled;

  const ManagerTile({
    super.key,
    required this.p,
    required this.mode,
    required this.oddsPct,
    required this.weightingEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final ctrl = ref.read(draftConfigProvider.notifier);
    final color = Color(p.colorValue);
    final isBidding = mode == DraftMode.bidding;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tk.scoreboardLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          JerseyChip(color: color, number: p.number, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _editName(context, ctrl),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(p.name,
                            overflow: TextOverflow.ellipsis,
                            style: tk.title.copyWith(fontSize: 18)),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit, size: 13, color: tk.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (isBidding)
                  _budgetRow(context, ctrl, tk)
                else if (weightingEnabled)
                  _oddsRow(context, ctrl, tk)
                else
                  Text('odds even', style: tk.body.copyWith(fontSize: 12, color: tk.textMuted)),
              ],
            ),
          ),
          if (!isBidding && weightingEnabled)
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  Text('${(oddsPct * 100).round()}%',
                      style: tk.displayLarge.copyWith(
                          fontSize: 20, color: _oddsColor(tk))),
                  Text('pick 1',
                      style: tk.body.copyWith(fontSize: 10, color: tk.textMuted)),
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: tk.textMuted),
            onPressed: () => ctrl.removeManager(p.id),
          ),
        ],
      ),
    );
  }

  Color _oddsColor(DraftTokens tk) {
    if (p.weight > 1.05) return tk.success;
    if (p.weight < 0.95) return tk.whistle;
    return tk.textPrimary;
  }

  Widget _oddsRow(BuildContext context, DraftConfigController ctrl, DraftTokens tk) {
    final label = p.weight > 1.05
        ? 'boosted'
        : p.weight < 0.95
            ? 'penalized'
            : 'even';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: _oddsColor(tk),
            inactiveTrackColor: tk.surfaceElevated,
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: p.weight.clamp(0.2, 5.0),
            min: 0.2,
            max: 5.0,
            onChanged: (v) => ctrl.setWeight(p.id, double.parse(v.toStringAsFixed(1))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text('odds ${p.weight.toStringAsFixed(1)}× · $label',
              style: tk.body.copyWith(fontSize: 11.5, color: _oddsColor(tk))),
        ),
      ],
    );
  }

  Widget _budgetRow(BuildContext context, DraftConfigController ctrl, DraftTokens tk) {
    return Row(
      children: [
        Text('💰 ColemanBucks',
            style: tk.body.copyWith(fontSize: 12.5, color: tk.textMuted)),
        const Spacer(),
        _StepButton(icon: Icons.remove, onTap: () => ctrl.setBudget(p.id, (p.budget - 10).clamp(0, 100000))),
        SizedBox(
          width: 46,
          child: Text('${p.budget}',
              textAlign: TextAlign.center,
              style: tk.displayLarge.copyWith(fontSize: 20, color: tk.gold)),
        ),
        _StepButton(icon: Icons.add, onTap: () => ctrl.setBudget(p.id, p.budget + 10)),
        const SizedBox(width: 4),
      ],
    );
  }

  void _editName(BuildContext context, DraftConfigController ctrl) {
    final controller = TextEditingController(text: p.name);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final tk = ctx.tokens;
        return AlertDialog(
          backgroundColor: tk.surface,
          title: Text('Manager name', style: tk.title),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: tk.body,
            decoration: const InputDecoration(hintText: 'Name'),
            onSubmitted: (_) => _save(ctx, ctrl, controller.text),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => _save(ctx, ctrl, controller.text),
                child: const Text('Save')),
          ],
        );
      },
    );
  }

  void _save(BuildContext ctx, DraftConfigController ctrl, String name) {
    if (name.trim().isNotEmpty) ctrl.updateManager(p.copyWith(name: name.trim()));
    Navigator.pop(ctx);
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: tk.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: tk.textPrimary),
      ),
    );
  }
}
