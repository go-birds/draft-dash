import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final tk = context.tokens;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
              color: tk.whistle.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: tk.whistle.withValues(alpha: .35)),
            ),
            child: Icon(Icons.warning_amber_rounded, color: tk.whistle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: tk.title.copyWith(fontSize: 20))),
        ],
      ),
      content: Text(
        message,
        style: tk.body.copyWith(color: tk.textMuted, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Cancel', style: TextStyle(color: tk.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tk.whistle,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
