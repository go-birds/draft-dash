import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/draft_mode.dart';
import '../../domain/draft/participant.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import 'jersey_chip.dart';

/// A roster row: jersey + name, plus an independent odds multiplier (auto
/// modes) or a ColemanBucks field (bidding mode). Edits flow straight to
/// [draftConfigProvider].
class ManagerTile extends ConsumerWidget {
  final Participant p;
  final DraftMode mode;
  final bool weightingEnabled;

  const ManagerTile({
    super.key,
    required this.p,
    required this.mode,
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
          JerseyChip(color: color, number: p.initials, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _editName(context, ref, ctrl),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          style: tk.title.copyWith(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit, size: 13, color: tk.textMuted),
                    ],
                  ),
                ),
                if (p.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.email!,
                    overflow: TextOverflow.ellipsis,
                    style: tk.body.copyWith(fontSize: 11, color: tk.textMuted),
                  ),
                ],
                const SizedBox(height: 4),
                if (isBidding)
                  _budgetRow(context, ctrl, tk)
                else if (weightingEnabled)
                  _oddsRow(context, ctrl, tk)
                else
                  Text(
                    'odds even',
                    style: tk.body.copyWith(fontSize: 12, color: tk.textMuted),
                  ),
              ],
            ),
          ),
          if (!isBidding && weightingEnabled)
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  Text(
                    '${p.weight.toStringAsFixed(1)}×',
                    style: tk.displayLarge.copyWith(
                      fontSize: 20,
                      color: _oddsColor(tk),
                    ),
                  ),
                  Text(
                    'mult.',
                    style: tk.body.copyWith(fontSize: 10, color: tk.textMuted),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: tk.textMuted),
            onPressed: () {
              final previous = ref.read(draftConfigProvider);
              ctrl.removeManager(p.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${p.name} removed'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => ref
                        .read(draftConfigProvider.notifier)
                        .restore(previous),
                  ),
                ),
              );
            },
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

  Widget _oddsRow(
    BuildContext context,
    DraftConfigController ctrl,
    DraftTokens tk,
  ) {
    final label = p.weight > 1.05
        ? 'boosted'
        : p.weight < 0.95
        ? 'penalized'
        : 'even';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              tooltip: 'Decrease ${p.name} odds',
              onTap: () => ctrl.setWeight(
                p.id,
                double.parse((p.weight - 0.1).toStringAsFixed(1)),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: _oddsColor(tk),
                  inactiveTrackColor: tk.surfaceElevated,
                  thumbColor: Colors.white,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  key: ValueKey('weight-slider-${p.id}'),
                  value: _weightToSlider(p.weight),
                  onChanged: (v) => ctrl.setWeight(p.id, _sliderToWeight(v)),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              tooltip: 'Increase ${p.name} odds',
              onTap: () => ctrl.setWeight(
                p.id,
                double.parse((p.weight + 0.1).toStringAsFixed(1)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            'multiplier ${p.weight.toStringAsFixed(1)}× · $label',
            style: tk.body.copyWith(fontSize: 11.5, color: _oddsColor(tk)),
          ),
        ),
      ],
    );
  }

  Widget _budgetRow(
    BuildContext context,
    DraftConfigController ctrl,
    DraftTokens tk,
  ) {
    return Row(
      children: [
        Text(
          '💰 ColemanBucks',
          style: tk.body.copyWith(fontSize: 12.5, color: tk.textMuted),
        ),
        const Spacer(),
        _StepButton(
          icon: Icons.remove,
          onTap: () => ctrl.setBudget(p.id, (p.budget - 10).clamp(0, 100000)),
        ),
        SizedBox(
          width: 46,
          child: Text(
            '${p.budget}',
            textAlign: TextAlign.center,
            style: tk.displayLarge.copyWith(fontSize: 20, color: tk.gold),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          onTap: () => ctrl.setBudget(p.id, p.budget + 10),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _editName(
    BuildContext context,
    WidgetRef ref,
    DraftConfigController ctrl,
  ) {
    final nameController = TextEditingController(text: p.name);
    final initialsController = TextEditingController(text: p.initials);
    final emailController = TextEditingController(text: p.email ?? '');
    final tauntController = TextEditingController(text: p.taunt ?? '');
    String? nameError;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final tk = ctx.tokens;
        return StatefulBuilder(
          builder: (ctx, setState) {
            void save() {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                setState(() => nameError = "Name can't be empty");
                return;
              }
              final taken = ref
                  .read(draftConfigProvider)
                  .participants
                  .any(
                    (other) =>
                        other.id != p.id &&
                        other.name.trim().toLowerCase() == name.toLowerCase(),
                  );
              if (taken) {
                setState(() => nameError = 'Name already taken');
                return;
              }
              final initials = _initials(initialsController.text);
              final email = emailController.text.trim();
              ctrl.updateManager(
                p.copyWith(
                  name: name,
                  initials: initials.isEmpty
                      ? Participant.initialsForName(name)
                      : initials,
                  email: email.isEmpty ? null : email,
                ),
              );
              ctrl.setTaunt(p.id, tauntController.text);
              Navigator.pop(ctx);
            }

            return AlertDialog(
              backgroundColor: tk.surface,
              title: Text('Manager name', style: tk.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: tk.body,
                    inputFormatters: [LengthLimitingTextInputFormatter(24)],
                    decoration: InputDecoration(
                      hintText: 'Name',
                      errorText: nameError,
                    ),
                    onChanged: (_) {
                      if (nameError != null) {
                        setState(() => nameError = null);
                      }
                    },
                    onSubmitted: (_) => save(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: initialsController,
                    style: tk.body,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [_InitialsFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Avatar letters',
                      hintText: 'Initials',
                    ),
                    onSubmitted: (_) => save(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    style: tk.body,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                      hintText: 'Send results to this address',
                    ),
                    onSubmitted: (_) => save(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tauntController,
                    style: tk.body,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Taunt',
                      hintText: 'Walk-up line for draft night',
                    ),
                    onSubmitted: (_) => save(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(onPressed: save, child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
  }
}

double _weightToSlider(double weight) {
  final value = weight.clamp(0.2, 5.0);
  if (value <= 1) return ((value - 0.2) / 0.8) * 0.5;
  return 0.5 + ((value - 1) / 4) * 0.5;
}

double _sliderToWeight(double value) {
  final weight = value <= 0.5
      ? 0.2 + (value / 0.5) * 0.8
      : 1 + ((value - 0.5) / 0.5) * 4;
  return double.parse(weight.toStringAsFixed(1));
}

String _initials(String value) {
  final letters = value.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
  return letters.length <= 3 ? letters : letters.substring(0, 3);
}

class _InitialsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final letters = _initials(newValue.text);
    return TextEditingValue(
      text: letters,
      selection: TextSelection.collapsed(offset: letters.length),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const _StepButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final button = InkWell(
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
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
