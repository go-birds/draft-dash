import 'package:flutter/material.dart';

import '../../domain/draft/participant.dart';
import '../theme/app_tokens.dart';
import 'jersey_chip.dart';

class TopPicksPodium extends StatelessWidget {
  final List<Participant> ordered;

  const TopPicksPodium({super.key, required this.ordered});

  @override
  Widget build(BuildContext context) {
    if (ordered.length < 3) return const SizedBox.shrink();

    final tk = context.tokens;
    final topThree = ordered.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: tk.scoreboard.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tk.scoreboardLine),
        boxShadow: [
          BoxShadow(
            color: tk.ice.withValues(alpha: .10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.military_tech_rounded, color: tk.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TOP PICK PODIUM',
                    style: tk.label.copyWith(color: tk.gold, letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LOCKED',
                style: tk.mono.copyWith(fontSize: 11, color: tk.led),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _PodiumSpot(rank: 2, participant: topThree[1])),
              const SizedBox(width: 10),
              Expanded(child: _PodiumSpot(rank: 1, participant: topThree[0])),
              const SizedBox(width: 10),
              Expanded(child: _PodiumSpot(rank: 3, participant: topThree[2])),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final int rank;
  final Participant participant;

  const _PodiumSpot({required this.rank, required this.participant});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final isWinner = rank == 1;
    final height = switch (rank) {
      1 => 72.0,
      2 => 56.0,
      _ => 46.0,
    };
    final label = switch (rank) {
      1 => '1ST',
      2 => '2ND',
      _ => '3RD',
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        JerseyChip(
          color: Color(participant.colorValue),
          number: participant.initials,
          size: isWinner ? 48 : 40,
          highlight: isWinner,
        ),
        const SizedBox(height: 8),
        Text(
          participant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: tk.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isWinner ? tk.gold : tk.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isWinner
                  ? [const Color(0xFFFFC04D), tk.gold]
                  : [tk.surfaceElevated, tk.surface],
            ),
            border: Border.all(color: isWinner ? tk.gold : tk.scoreboardLine),
          ),
          child: Text(
            label,
            style: tk.label.copyWith(
              fontSize: 12,
              color: isWinner ? const Color(0xFF241500) : tk.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
