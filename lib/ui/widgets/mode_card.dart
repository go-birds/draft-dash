import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String blurb;
  final String bestFor;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const ModeCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.blurb,
    required this.bestFor,
    required this.selected,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? tk.gold.withValues(alpha: .10) : tk.surface,
            border: Border.all(
              color: selected ? tk.gold : tk.scoreboardLine,
              width: selected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  IconButton(
                    onPressed: onInfoTap,
                    icon: const Icon(Icons.info_outline_rounded),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'How ${title.toLowerCase()} works',
                    color: selected ? tk.gold : tk.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tk.displayLarge.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 2),
              Text(
                blurb,
                maxLines: 2,
                style: tk.body.copyWith(
                  fontSize: 10.5,
                  color: tk.textMuted,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'BEST FOR',
                style: tk.label.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 1.1,
                  color: tk.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                bestFor,
                maxLines: 2,
                style: tk.body.copyWith(
                  fontSize: 11,
                  color: tk.ice,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
