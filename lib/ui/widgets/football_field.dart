import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/color_utils.dart';

/// One runner's live state for the race painter.
class RaceRunner {
  final Color color;
  final String number;
  final double progress; // 0..1 toward the goal line
  final double stride; // running-leg phase
  final bool leader;

  const RaceRunner({
    required this.color,
    required this.number,
    required this.progress,
    required this.stride,
    required this.leader,
  });
}

/// Paints a horizontal football field (mowed stripes, yard lines, end zone)
/// and the running-back sprites at their current progress.
class FieldRacePainter extends CustomPainter {
  final List<RaceRunner> runners;
  final DraftTokens tk;

  FieldRacePainter({required this.runners, required this.tk});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final endZoneW = w * 0.15;
    final playW = w - endZoneW;

    // mowed vertical stripes
    final stripe = playW / 10;
    for (var i = 0; i < 10; i++) {
      final p = Paint()..color = i.isEven ? tk.turf : tk.turfDark;
      canvas.drawRect(Rect.fromLTWH(i * stripe, 0, stripe + 1, h), p);
    }

    // end zone
    final ezPaint = Paint()..color = tk.endZone;
    canvas.drawRect(Rect.fromLTWH(playW, 0, endZoneW, h), ezPaint);
    final ezStripe = Paint()..color = tk.endZoneDark;
    for (var y = 0.0; y < h; y += 18) {
      canvas.drawRect(Rect.fromLTWH(playW, y, endZoneW, 9), ezStripe);
    }
    // goal line
    canvas.drawRect(
        Rect.fromLTWH(playW - 2.5, 0, 5, h), Paint()..color = tk.yardLine);

    // yard lines + numbers
    final line = Paint()
      ..color = tk.yardLine.withValues(alpha: .55)
      ..strokeWidth = 2;
    final yards = [40, 30, 20, 10];
    for (var i = 1; i <= 4; i++) {
      final x = playW * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, h), line);
      _yardNumber(canvas, '${yards[i - 1]}', x, h);
    }
    // 50 at midfield
    final midX = playW * 0.5;
    _yardNumber(canvas, '50', midX, h, big: true);

    // lighting vignette
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.4, -0.2),
          radius: 1.0,
          colors: [Colors.white.withValues(alpha: .10), Colors.transparent],
        ).createShader(Offset.zero & size),
    );

    // end-zone label (vertical)
    _endZoneLabel(canvas, playW + endZoneW / 2, h);

    // runners
    final n = runners.length;
    final laneH = h / n;
    final startX = w * 0.05;
    final goalX = playW + endZoneW * 0.35;
    for (var i = 0; i < n; i++) {
      final r = runners[i];
      final cx = startX + (goalX - startX) * r.progress.clamp(0.0, 1.0);
      final cy = laneH * (i + 0.5);
      final s = min(laneH * 0.78, 78.0);
      _drawRunner(canvas, Offset(cx, cy), s, r);
    }
  }

  void _drawRunner(Canvas c, Offset center, double s, RaceRunner r) {
    final color = r.color;
    final skin = const Color(0xFFE7B58A);
    final stride = sin(r.stride) * 0.5;

    // shadow
    c.drawOval(
      Rect.fromCenter(
          center: center.translate(0, s * 0.46), width: s * 0.7, height: s * 0.16),
      Paint()..color = Colors.black.withValues(alpha: .28),
    );

    // speed lines for the leader
    if (r.leader) {
      final lp = Paint()
        ..color = Colors.white.withValues(alpha: .45)
        ..strokeWidth = 2;
      for (var k = 0; k < 3; k++) {
        final y = center.dy - s * 0.1 + k * s * 0.12;
        c.drawLine(Offset(center.dx - s * 0.55, y),
            Offset(center.dx - s * 0.9, y), lp);
      }
    }

    final hipY = center.dy + s * 0.10;
    final shoulderY = center.dy - s * 0.16;

    final pants = Paint()
      ..color = const Color(0xFFF1F4F8)
      ..strokeWidth = s * 0.13
      ..strokeCap = StrokeCap.round;
    final cleat = Paint()
      ..color = const Color(0xFF15171C)
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round;

    // back leg
    final backFoot = Offset(center.dx - s * 0.22 - stride * s * 0.2, center.dy + s * 0.42);
    c.drawLine(Offset(center.dx, hipY), backFoot, pants);
    c.drawLine(backFoot, backFoot.translate(-s * 0.14, s * 0.02), cleat);
    // front leg
    final frontFoot = Offset(center.dx + s * 0.20 + stride * s * 0.2, center.dy + s * 0.40);
    c.drawLine(Offset(center.dx, hipY), frontFoot, pants);
    c.drawLine(frontFoot, frontFoot.translate(s * 0.16, s * 0.02), cleat);

    // torso (jersey)
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(center.dx, (hipY + shoulderY) / 2),
          width: s * 0.42,
          height: hipY - shoulderY + s * 0.1),
      Radius.circular(s * 0.12),
    );
    c.drawRRect(torso, Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: jerseyGradient(color)).createShader(torso.outerRect));

    // number
    _text(c, r.number, Offset(center.dx, (hipY + shoulderY) / 2),
        s * 0.30, onColor(color), bold: true);

    // back arm
    final arm = Paint()
      ..color = color
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(center.dx - s * 0.05, shoulderY + s * 0.08),
        Offset(center.dx - s * 0.28, shoulderY - stride * s * 0.1), arm);
    c.drawCircle(Offset(center.dx - s * 0.30, shoulderY - stride * s * 0.1),
        s * 0.06, Paint()..color = skin);

    // front arm + football
    c.drawLine(Offset(center.dx + s * 0.10, shoulderY + s * 0.08),
        Offset(center.dx + s * 0.30, shoulderY + s * 0.04), arm);
    final ballC = Offset(center.dx + s * 0.40, shoulderY + s * 0.06);
    c.save();
    c.translate(ballC.dx, ballC.dy);
    c.rotate(0.5);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.30, height: s * 0.18),
        Paint()..color = const Color(0xFF834F25));
    c.drawLine(Offset(-s * 0.10, 0), Offset(s * 0.10, 0),
        Paint()..color = const Color(0xFFF5EAD6)..strokeWidth = s * 0.02);
    c.restore();

    // head + helmet
    final headC = Offset(center.dx + s * 0.02, shoulderY - s * 0.16);
    c.drawCircle(headC, s * 0.13, Paint()..color = skin);
    final helmet = Path()
      ..addArc(Rect.fromCircle(center: headC, radius: s * 0.15), pi, pi)
      ..arcTo(Rect.fromCircle(center: headC.translate(s * 0.04, 0), radius: s * 0.15),
          0, pi / 2, false);
    c.drawPath(helmet, Paint()..color = darken(color, .05));
    // facemask
    c.drawArc(Rect.fromCircle(center: headC.translate(s * 0.06, 0), radius: s * 0.13),
        -pi / 3, pi / 1.6, false,
        Paint()
          ..color = const Color(0xFFE2E7EE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02);
  }

  void _yardNumber(Canvas c, String s, double x, double h, {bool big = false}) {
    _text(c, s, Offset(x, h * 0.5), big ? 30 : 24,
        tk.yardLine.withValues(alpha: .5));
  }

  void _endZoneLabel(Canvas c, double cx, double h) {
    c.save();
    c.translate(cx, h / 2);
    c.rotate(pi / 2);
    _text(c, 'END ZONE', Offset.zero, 26, Colors.white.withValues(alpha: .85),
        bold: true, spacing: 6);
    c.restore();
  }

  void _text(Canvas c, String s, Offset center, double size, Color color,
      {bool bold = false, double spacing = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: bold ? 'Anton' : 'Inter',
          fontSize: size,
          color: color,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(FieldRacePainter old) => true;
}
