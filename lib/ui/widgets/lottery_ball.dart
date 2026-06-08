import 'package:flutter/material.dart';

/// A glossy white ping-pong ball with the manager's number in a colored ring.
class LotteryBall extends StatelessWidget {
  final Color color;
  final String number;
  final double size;
  final bool highlight;

  const LotteryBall({
    super.key,
    required this.color,
    required this.number,
    this.size = 48,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 1.0,
          colors: [Color(0xFFFFFFFF), Color(0xFFF2F3F5), Color(0xFFD7DADF)],
          stops: [0, .55, 1],
        ),
        border: highlight
            ? Border.all(color: const Color(0xFFF5A524), width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.08),
          ),
          if (highlight)
            const BoxShadow(color: Color(0x66F5A524), blurRadius: 18),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.66,
        height: size * 0.66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: color, width: size * 0.055),
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: TextStyle(
            fontFamily: 'Anton',
            fontSize: size * 0.34,
            color: color,
          ),
        ),
      ),
    );
  }
}
