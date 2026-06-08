import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/participant.dart';
import '../../services/feedback.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/jersey_chip.dart';
import 'result_screen.dart';

/// Card-flip reveal: tap to flip each card in pick order.
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  int _revealed = 0; // number of cards flipped, in pick order

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final result = ref.watch(draftControllerProvider);
    final cfg = ref.watch(draftConfigProvider);
    final byId = {for (final p in cfg.participants) p.id: p};
    final order = result?.order ?? const [];
    final picks = [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
    final n = picks.length;
    final allDone = _revealed >= n;

    void flipNext() {
      if (_revealed >= n) return;
      AppFeedback.of(ref).cardFlip();
      setState(() => _revealed += 1);
    }

    return Scaffold(
      backgroundColor: tk.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'CARD FLIP DRAFT',
              style: tk.label.copyWith(color: tk.gold, letterSpacing: 4),
            ),
            Text(
              allDone ? 'THE BOARD IS SET' : 'TAP TO REVEAL',
              style: tk.displayLarge.copyWith(fontSize: 28),
            ),
            Text(
              '$_revealed of $n picks revealed',
              style: tk.label.copyWith(fontSize: 11, color: tk.textMuted),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                itemCount: n,
                itemBuilder: (_, i) => _FlipCard(
                  pick: i + 1,
                  participant: picks[i],
                  revealed: i < _revealed,
                  isNext: i == _revealed,
                  onTap: i == _revealed ? flipNext : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: allDone
                  ? PrimaryButton(
                      'SEE THE BOARD ✓',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const ResultScreen(),
                          ),
                        );
                      },
                    )
                  : GhostButton(
                      '⤓ REVEAL ALL',
                      onPressed: () {
                        AppFeedback.of(ref).cardFlip();
                        setState(() => _revealed = n);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  final int pick;
  final Participant participant;
  final bool revealed;
  final bool isNext;
  final VoidCallback? onTap;

  const _FlipCard({
    required this.pick,
    required this.participant,
    required this.revealed,
    required this.isNext,
    required this.onTap,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    if (widget.revealed) _c.value = 1;
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.revealed && !old.revealed) _c.forward();
    if (!widget.revealed && old.revealed) _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final angle = _c.value * pi;
          final showFront = angle < pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showFront
                ? _CardBack(isNext: widget.isNext, pick: widget.pick)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _CardFace(pick: widget.pick, p: widget.participant),
                  ),
          );
        },
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final bool isNext;
  final int pick;
  const _CardBack({required this.isNext, required this.pick});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext ? tk.gold : tk.scoreboardLine,
          width: isNext ? 2 : 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tk.surfaceElevated, tk.surface],
        ),
        boxShadow: isNext
            ? [BoxShadow(color: tk.gold.withValues(alpha: .25), blurRadius: 18)]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏈', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              'PICK $pick',
              style: tk.displayLarge.copyWith(fontSize: 18, color: tk.gold),
            ),
            if (isNext)
              Text(
                'TAP!',
                style: tk.label.copyWith(fontSize: 11, color: tk.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final int pick;
  final Participant p;
  const _CardFace({required this.pick, required this.p});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final ordinal = switch (pick) {
      1 => '1ST',
      2 => '2ND',
      3 => '3RD',
      _ => '${pick}TH',
    };
    return Container(
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pick == 1 ? tk.gold : tk.scoreboardLine),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 12,
            child: Text(
              ordinal,
              style: tk.displayLarge.copyWith(fontSize: 16, color: tk.gold),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                JerseyChip(
                  color: Color(p.colorValue),
                  number: p.number,
                  size: 58,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      p.name.toUpperCase(),
                      style: tk.displayLarge.copyWith(fontSize: 20),
                    ),
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
