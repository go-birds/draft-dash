import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String blurb;
  final bool selected;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.blurb,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
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
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tk.displayLarge.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                blurb,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tk.body.copyWith(
                  fontSize: 11,
                  color: tk.textMuted,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
