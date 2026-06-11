import 'dart:math';

import 'package:flutter/material.dart';

/// Confetti strip colors.
///
/// Mirrors `kJerseyPalette` in lib/ui/state/providers.dart — copied here so
/// this widget stays a pure-rendering import (no provider/storage deps).
const _kConfettiColors = <Color>[
  Color(0xFF3A86FF),
  Color(0xFFE63946),
  Color(0xFFFFB703),
  Color(0xFF06D6A0),
  Color(0xFF9B5DE5),
  Color(0xFFFB5607),
  Color(0xFF34C759),
  Color(0xFFFF5DA2),
  Color(0xFF4CC9F0),
  Color(0xFFB5179E),
  Color(0xFF8AC926),
  Color(0xFFF15BB5),
];

/// One-shot celebration burst meant to sit over content in a [Stack].
///
/// ~100 jersey-colored strips erupt from the top, fall with gravity,
/// horizontal drift, and spin over ~2.5s, fading out at the end. The particle
/// field is seeded so each instance is deterministic. Wrapped in
/// [IgnorePointer] so it never blocks taps, and renders nothing when the
/// platform asks for reduced motion ([MediaQuery.disableAnimationsOf]).
class ConfettiOverlay extends StatefulWidget {
  /// Seed for the particle field, so a given instance always bursts the same.
  final int seed;

  const ConfettiOverlay({super.key, this.seed = 7});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;
  late final List<_ConfettiParticle> _particles;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _particles = _ConfettiParticle.burst(Random(widget.seed));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Play exactly once, and never when the platform disables animations.
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _burst.forward();
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _burst,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(particles: _particles, t: _burst.value),
        ),
      ),
    );
  }
}

/// One confetti strip. Positions/velocities are fractions of the painted
/// size; sizes are logical pixels.
class _ConfettiParticle {
  final Color color;
  final double x0; // launch x, fraction of width
  final double y0; // launch y, fraction of height
  final double vx; // horizontal drift over the full animation
  final double vy; // initial vertical velocity (negative = upward pop)
  final double w; // strip width, px
  final double h; // strip height, px
  final double rot; // initial rotation, radians
  final double spin; // total spin over the animation, radians

  const _ConfettiParticle({
    required this.color,
    required this.x0,
    required this.y0,
    required this.vx,
    required this.vy,
    required this.rot,
    required this.spin,
    required this.w,
    required this.h,
  });

  static List<_ConfettiParticle> burst(Random rng, {int count = 100}) {
    return List.generate(count, (i) {
      return _ConfettiParticle(
        color: _kConfettiColors[i % _kConfettiColors.length],
        x0: 0.5 + (rng.nextDouble() - 0.5) * 0.5,
        y0: 0.02 + rng.nextDouble() * 0.16,
        vx: (rng.nextDouble() - 0.5) * 1.3,
        vy: -(0.2 + rng.nextDouble() * 0.8),
        rot: rng.nextDouble() * 2 * pi,
        spin: (rng.nextDouble() - 0.5) * 12,
        w: 3.0 + rng.nextDouble() * 3.0,
        h: 8.0 + rng.nextDouble() * 7.0,
      );
    });
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double t; // 0..1 animation progress

  _ConfettiPainter({required this.particles, required this.t});

  static const _gravity = 2.6; // fraction of height per t^2
  static const _fadeStart = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1 || size.isEmpty) return;
    final fade = t < _fadeStart
        ? 1.0
        : (1.0 - (t - _fadeStart) / (1.0 - _fadeStart)).clamp(0.0, 1.0);
    final paintBrush = Paint();
    for (final p in particles) {
      final px = (p.x0 + p.vx * t) * size.width;
      final py = (p.y0 + p.vy * t + _gravity * t * t) * size.height;
      if (py < -20 || py > size.height + 20) continue;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rot + p.spin * t);
      paintBrush.color = p.color.withValues(alpha: fade);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
        paintBrush,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.t != t || old.particles != particles;
}
