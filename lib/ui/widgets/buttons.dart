import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Big gold call-to-action with the Anton display face.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;

  const PrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = 60,
    this.fontSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFFFFC04D), tk.gold],
              ),
              boxShadow: [
                BoxShadow(
                  color: tk.gold.withValues(alpha: .35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF241500), size: fontSize + 4),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Anton',
                    fontSize: fontSize,
                    letterSpacing: .5,
                    color: const Color(0xFF241500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined "ghost" button on the scoreboard chrome.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color? textColor;

  const GhostButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final c = textColor ?? tk.textPrimary;
    return Material(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tk.scoreboardLine),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: c, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: .8,
                  color: c,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
