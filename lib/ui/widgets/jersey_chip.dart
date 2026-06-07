import 'package:flutter/material.dart';

import '../theme/color_utils.dart';

/// The universal "manager" token: a rounded jersey square with a number.
class JerseyChip extends StatelessWidget {
  final Color color;
  final String number;
  final double size;
  final bool highlight; // gold ring for winners/leaders
  final bool circular; // lottery balls use this

  const JerseyChip({
    super.key,
    required this.color,
    required this.number,
    this.size = 46,
    this.highlight = false,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = circular ? size / 2 : size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: jerseyGradient(color),
        ),
        border: highlight
            ? Border.all(color: const Color(0xFFF5A524), width: size * 0.06)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.08),
          ),
          if (highlight)
            BoxShadow(
              color: const Color(0xFFF5A524).withValues(alpha: .5),
              blurRadius: size * 0.4,
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          fontFamily: 'Anton',
          fontSize: size * 0.5,
          height: 1.0,
          color: onColor(color),
        ),
      ),
    );
  }
}
