import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/color_utils.dart';

/// One runner's live state for the race painter.
class RaceRunner {
  final Color color;
  final String initials;
  final double progress; // 0..1 from goal line to far end zone
  final double stride; // running-leg phase
  final bool winner;

  const RaceRunner({
    required this.color,
    required this.initials,
    required this.progress,
    required this.stride,
    this.winner = false,
  });
}

/// Paints a horizontal football field (mowed stripes, yard lines, end zone)
/// and the running-back sprites at their current progress.
class FieldRacePainter extends CustomPainter {
  final List<RaceRunner> runners;
  final double leaderProgress;
  final double introProgress;
  final bool racing;
  final bool finished;
  final DraftTokens tk;

  FieldRacePainter({
    required this.runners,
    required this.leaderProgress,
    required this.introProgress,
    required this.racing,
    required this.finished,
    required this.tk,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const visibleYards = 40.0;
    const finishYard = 105.0;
    final cameraStart = (leaderProgress * finishYard - 20).clamp(-10.0, 70.0);
    double xForYard(double yard) => ((yard - cameraStart) / visibleYards) * w;
    final intro = Curves.easeOutCubic.transform(introProgress.clamp(0.0, 1.0));
    // Keep every glow/burst hidden until the result is actually finished.
    // Pre-finish effects can reveal which runner is destined to win.
    final finishPulse = finished ? 1.0 : 0.0;

    if (tk.sport == SportPresentation.basketball) {
      _drawBasketballCourt(canvas, size, cameraStart, xForYard);
    } else {
      // Mowed stripes every five yards across the 40-yard camera window.
      for (
        var yard = cameraStart.floor() - 5;
        yard <= cameraStart + 45;
        yard++
      ) {
        if (yard % 5 != 0) continue;
        final x0 = xForYard(yard.toDouble());
        final x1 = xForYard(yard + 5);
        final stripeIndex = (yard ~/ 5).abs();
        canvas.drawRect(
          Rect.fromLTRB(x0, 0, x1 + 1, h),
          Paint()..color = stripeIndex.isEven ? tk.turf : tk.turfDark,
        );
      }

      // End zones just outside the 100-yard field.
      _drawEndZone(canvas, Rect.fromLTRB(xForYard(-10), 0, xForYard(0), h));
      _drawEndZone(canvas, Rect.fromLTRB(xForYard(100), 0, xForYard(110), h));
    }

    if (!racing) {
      _drawIntroLane(canvas, Rect.fromLTRB(0, 0, xForYard(14), h), intro);
    }

    if (tk.sport == SportPresentation.football) {
      // Yard lines, hash marks, and numbers belong only on the gridiron.
      final majorLine = Paint()
        ..color = tk.yardLine.withValues(alpha: .62)
        ..strokeWidth = 2;
      final minorLine = Paint()
        ..color = tk.yardLine.withValues(alpha: .28)
        ..strokeWidth = 1;
      for (var yard = 0; yard <= 100; yard += 5) {
        final x = xForYard(yard.toDouble());
        if (x < -30 || x > w + 30) continue;
        final major = yard % 10 == 0;
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, h),
          major ? majorLine : minorLine,
        );
        _hashMarks(canvas, x, h);
        if (major && yard > 0 && yard < 100) {
          _yardNumber(canvas, _yardLabel(yard), x, h * .23);
          _yardNumber(canvas, _yardLabel(yard), x, h * .77, flipped: true);
        }
      }
    }

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

    if (tk.sport == SportPresentation.football) {
      _endZoneLabel(canvas, xForYard(-5), h);
      _endZoneLabel(canvas, xForYard(105), h);
    } else {
      _baselineLabel(canvas, xForYard(-5), h);
      _baselineLabel(canvas, xForYard(105), h);
    }

    // runners
    final n = runners.length;
    final laneH = h / n;
    for (var i = 0; i < n; i++) {
      final r = runners[i];
      final cx = racing
          ? xForYard(finishYard * r.progress.clamp(0.0, 1.0))
          : xForYard(
              (-12 + (i * 0.9)) +
                  ((4.0 - i * 0.12) - (-12 + (i * 0.9))) * intro,
            );
      final cy = laneH * (i + 0.5);
      final s = min(laneH * 0.78, 78.0);
      _drawRunner(canvas, Offset(cx, cy), s, r);
    }

    if (finishPulse > 0) {
      _drawFinishGlow(canvas, xForYard(100), h, finishPulse);
    }
  }

  void _drawIntroLane(Canvas canvas, Rect rect, double intro) {
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: .40 + .18 * intro),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final guide = Paint()
      ..color = Colors.white.withValues(alpha: .16 + .16 * intro)
      ..strokeWidth = 2;
    final x = rect.right - 2;
    canvas.drawLine(Offset(x, rect.top + 8), Offset(x, rect.bottom - 8), guide);
    for (var i = 0; i < 3; i++) {
      final dy = rect.top + rect.height * (0.22 + i * 0.23);
      canvas.drawLine(
        Offset(rect.left + 16, dy),
        Offset(rect.left + rect.width - 18, dy),
        Paint()
          ..color = tk.gold.withValues(alpha: .08 + .09 * intro)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke,
      );
    }
    _text(
      canvas,
      'LANE INTRO',
      Offset(rect.left + 54, rect.top + 28),
      18,
      tk.gold.withValues(alpha: .85),
      bold: true,
      spacing: 2,
    );
  }

  void _drawFinishGlow(Canvas canvas, double goalX, double h, double pulse) {
    final goalLine = Paint()
      ..color = tk.gold.withValues(alpha: .35 + .4 * pulse)
      ..strokeWidth = 5 + 6 * pulse;
    canvas.drawLine(Offset(goalX, 0), Offset(goalX, h), goalLine);

    final glowRect = Rect.fromLTRB(goalX - 26, 0, goalX + 48, h);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            tk.gold.withValues(alpha: .02),
            tk.gold.withValues(alpha: .18 + .22 * pulse),
            Colors.white.withValues(alpha: .12 + .12 * pulse),
          ],
          stops: const [0.0, 0.64, 1.0],
        ).createShader(glowRect),
    );

    final burst = Paint()
      ..color = Colors.white.withValues(alpha: .28 * pulse)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final laneY = h * (0.15 + i * 0.14);
      canvas.drawLine(
        Offset(goalX - 12 - i * 3, laneY),
        Offset(goalX + 28 + i * 4, laneY),
        burst,
      );
    }
  }

  void _drawEndZone(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = tk.endZone);
    final ezStripe = Paint()..color = tk.endZoneDark;
    for (var y = rect.top; y < rect.bottom; y += 18) {
      canvas.drawRect(Rect.fromLTWH(rect.left, y, rect.width, 9), ezStripe);
    }
  }

  void _drawBasketballCourt(
    Canvas canvas,
    Size size,
    double cameraStart,
    double Function(double) xForYard,
  ) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tk.turf);

    // Long hardwood boards, with alternating warm tones and fine seams.
    const boardHeight = 34.0;
    for (var y = 0.0; y < size.height; y += boardHeight) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, boardHeight),
        Paint()
          ..color = ((y / boardHeight).round()).isEven ? tk.turf : tk.turfDark,
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = tk.yardLine.withValues(alpha: .14)
          ..strokeWidth = 1,
      );
    }
    for (
      var yard = cameraStart.floor() - 5;
      yard <= cameraStart + 45;
      yard += 4
    ) {
      final x = xForYard(yard.toDouble());
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = tk.yardLine.withValues(alpha: .10)
          ..strokeWidth = 1,
      );
    }

    final courtLine = Paint()
      ..color = tk.yardLine.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final centerX = xForYard(50);
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      courtLine,
    );
    canvas.drawCircle(Offset(centerX, size.height / 2), 66, courtLine);

    for (final baseline in [0.0, 100.0]) {
      final x = xForYard(baseline);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), courtLine);
      final facingRight = baseline == 0;
      final laneRect = Rect.fromCenter(
        center: Offset(x + (facingRight ? 54 : -54), size.height / 2),
        width: 108,
        height: min(230, size.height * .52),
      );
      canvas.drawRect(laneRect, courtLine);
      canvas.drawCircle(
        Offset(
          laneRect.center.dx + (facingRight ? 54 : -54),
          laneRect.center.dy,
        ),
        54,
        courtLine,
      );
    }
  }

  void _drawRunner(Canvas c, Offset center, double s, RaceRunner r) {
    if (tk.sport == SportPresentation.basketball) {
      _drawBasketballRunner(c, center, s, r);
      return;
    }
    final color = r.color;
    final skin = const Color(0xFFE7B58A);
    final stride = sin(r.stride);
    final counter = cos(r.stride);
    final bob = sin(r.stride * 2) * s * 0.025;
    center = center.translate(0, bob);

    // shadow
    c.drawOval(
      Rect.fromCenter(
        center: center.translate(0, s * 0.46),
        width: s * 0.7,
        height: s * 0.16,
      ),
      Paint()..color = Colors.black.withValues(alpha: .28),
    );

    // The three-line burst is a finish effect, never an early winner tell.
    if (r.winner) {
      final lp = Paint()
        ..color = Colors.white.withValues(alpha: .45)
        ..strokeWidth = 2;
      for (var k = 0; k < 3; k++) {
        final y = center.dy - s * 0.1 + k * s * 0.12;
        c.drawLine(
          Offset(center.dx - s * 0.55, y),
          Offset(center.dx - s * 0.9, y),
          lp,
        );
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
    final backFoot = Offset(
      center.dx - s * 0.24 - stride * s * 0.23,
      center.dy + s * 0.42 + counter * s * .04,
    );
    c.drawLine(Offset(center.dx, hipY), backFoot, pants);
    c.drawLine(backFoot, backFoot.translate(-s * 0.14, s * 0.02), cleat);
    // front leg
    final frontFoot = Offset(
      center.dx + s * 0.22 + stride * s * 0.23,
      center.dy + s * 0.40 - counter * s * .04,
    );
    c.drawLine(Offset(center.dx, hipY), frontFoot, pants);
    c.drawLine(frontFoot, frontFoot.translate(s * 0.16, s * 0.02), cleat);

    // torso (jersey)
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, (hipY + shoulderY) / 2),
        width: s * 0.42,
        height: hipY - shoulderY + s * 0.1,
      ),
      Radius.circular(s * 0.12),
    );
    c.drawRRect(
      torso,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: jerseyGradient(color),
        ).createShader(torso.outerRect),
    );

    // number
    _text(
      c,
      r.initials,
      Offset(center.dx, (hipY + shoulderY) / 2),
      s * 0.30,
      onColor(color),
      bold: true,
    );

    // back arm
    final arm = Paint()
      ..color = color
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round;
    c.drawLine(
      Offset(center.dx - s * 0.05, shoulderY + s * 0.08),
      Offset(center.dx - s * 0.28, shoulderY - stride * s * 0.18),
      arm,
    );
    c.drawCircle(
      Offset(center.dx - s * 0.30, shoulderY - stride * s * 0.18),
      s * 0.06,
      Paint()..color = skin,
    );

    // front arm + football
    c.drawLine(
      Offset(center.dx + s * 0.10, shoulderY + s * 0.08),
      Offset(center.dx + s * 0.30, shoulderY + s * 0.04 + stride * s * .10),
      arm,
    );
    final ballC = Offset(
      center.dx + s * 0.40,
      shoulderY + s * 0.06 + stride * s * .08,
    );
    c.save();
    c.translate(ballC.dx, ballC.dy);
    c.rotate(0.5);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.30, height: s * 0.18),
      Paint()..color = const Color(0xFF834F25),
    );
    c.drawLine(
      Offset(-s * 0.10, 0),
      Offset(s * 0.10, 0),
      Paint()
        ..color = const Color(0xFFF5EAD6)
        ..strokeWidth = s * 0.02,
    );
    c.restore();

    // head + helmet
    final headC = Offset(center.dx + s * 0.02, shoulderY - s * 0.16);
    c.drawCircle(headC, s * 0.13, Paint()..color = skin);
    final helmet = Path()
      ..addArc(Rect.fromCircle(center: headC, radius: s * 0.15), pi, pi)
      ..arcTo(
        Rect.fromCircle(center: headC.translate(s * 0.04, 0), radius: s * 0.15),
        0,
        pi / 2,
        false,
      );
    c.drawPath(helmet, Paint()..color = darken(color, .05));
    // facemask
    c.drawArc(
      Rect.fromCircle(center: headC.translate(s * 0.06, 0), radius: s * 0.13),
      -pi / 3,
      pi / 1.6,
      false,
      Paint()
        ..color = const Color(0xFFE2E7EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );

    if (r.winner) {
      _drawFirstPickBadge(c, center.translate(s * 0.08, -s * 0.62), s);
    }
  }

  void _drawBasketballRunner(Canvas c, Offset center, double s, RaceRunner r) {
    final color = r.color;
    const skin = Color(0xFFE7B58A);
    final stride = sin(r.stride);
    final bob = sin(r.stride * 2) * s * .025;
    center = center.translate(0, bob);

    c.drawOval(
      Rect.fromCenter(
        center: center.translate(0, s * .45),
        width: s * .72,
        height: s * .15,
      ),
      Paint()..color = Colors.black.withValues(alpha: .22),
    );

    if (r.winner) {
      final burst = Paint()
        ..color = Colors.white.withValues(alpha: .62)
        ..strokeWidth = 2;
      for (var k = 0; k < 3; k++) {
        final y = center.dy - s * .1 + k * s * .12;
        c.drawLine(
          Offset(center.dx - s * .55, y),
          Offset(center.dx - s * .9, y),
          burst,
        );
      }
    }

    final hip = Offset(center.dx, center.dy + s * .1);
    final shoulder = Offset(center.dx, center.dy - s * .18);
    final limb = Paint()
      ..color = skin
      ..strokeWidth = s * .1
      ..strokeCap = StrokeCap.round;
    final shoe = Paint()
      ..color = const Color(0xFFF8F8FA)
      ..strokeWidth = s * .08
      ..strokeCap = StrokeCap.round;
    final leftFoot = Offset(
      center.dx - s * .2 - stride * s * .2,
      center.dy + s * .43,
    );
    final rightFoot = Offset(
      center.dx + s * .2 + stride * s * .2,
      center.dy + s * .43,
    );
    c.drawLine(hip, leftFoot, limb);
    c.drawLine(hip, rightFoot, limb);
    c.drawLine(leftFoot, leftFoot.translate(-s * .12, 0), shoe);
    c.drawLine(rightFoot, rightFoot.translate(s * .12, 0), shoe);

    final jersey = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, (hip.dy + shoulder.dy) / 2),
        width: s * .43,
        height: hip.dy - shoulder.dy + s * .12,
      ),
      Radius.circular(s * .06),
    );
    c.drawRRect(jersey, Paint()..color = color);
    _text(c, r.initials, jersey.center, s * .27, onColor(color), bold: true);

    c.drawLine(
      shoulder.translate(-s * .08, s * .05),
      shoulder.translate(-s * .3, -stride * s * .16),
      limb,
    );
    final ballCenter = shoulder.translate(s * .38, s * .04 + stride * s * .08);
    c.drawLine(shoulder.translate(s * .08, s * .05), ballCenter, limb);
    final ballPaint = Paint()..color = const Color(0xFFE36B25);
    c.drawCircle(ballCenter, s * .14, ballPaint);
    final seam = Paint()
      ..color = const Color(0xFF4A2415)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, s * .015);
    c.drawCircle(ballCenter, s * .14, seam);
    c.drawLine(
      ballCenter.translate(-s * .14, 0),
      ballCenter.translate(s * .14, 0),
      seam,
    );
    c.drawArc(
      Rect.fromCircle(center: ballCenter, radius: s * .14),
      -pi / 2,
      pi,
      false,
      seam,
    );

    final head = shoulder.translate(0, -s * .17);
    c.drawCircle(head, s * .14, Paint()..color = skin);
    c.drawArc(
      Rect.fromCircle(center: head, radius: s * .145),
      pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFF282018)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .07,
    );

    if (r.winner) {
      _drawFirstPickBadge(c, center.translate(s * .08, -s * .62), s);
    }
  }

  void _drawFirstPickBadge(Canvas c, Offset center, double s) {
    final badge = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: s * 1.04, height: s * 0.34),
      Radius.circular(s * 0.17),
    );
    c.drawRRect(
      badge.shift(Offset(0, s * 0.04)),
      Paint()..color = Colors.black.withValues(alpha: .35),
    );
    c.drawRRect(badge, Paint()..color = tk.gold);
    c.drawRRect(
      badge,
      Paint()
        ..color = Colors.white.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _text(
      c,
      '1ST PICK',
      center,
      s * 0.18,
      const Color(0xFF241500),
      bold: true,
      spacing: 1.1,
    );
  }

  String _yardLabel(int yard) =>
      yard == 50 ? '50' : '${yard < 50 ? yard : 100 - yard}';

  void _hashMarks(Canvas c, double x, double h) {
    final p = Paint()
      ..color = tk.yardLine.withValues(alpha: .45)
      ..strokeWidth = 1.5;
    const hashW = 10.0;
    for (final y in [h * .34, h * .66]) {
      c.drawLine(Offset(x - hashW / 2, y), Offset(x + hashW / 2, y), p);
    }
  }

  void _yardNumber(
    Canvas c,
    String s,
    double x,
    double y, {
    bool flipped = false,
  }) {
    c.save();
    if (flipped) {
      c.translate(x, y);
      c.rotate(pi);
      x = 0;
      y = 0;
    }
    _text(
      c,
      s,
      Offset(x, y),
      s == '50' ? 30 : 24,
      tk.yardLine.withValues(alpha: .5),
    );
    c.restore();
  }

  void _endZoneLabel(Canvas c, double cx, double h) {
    c.save();
    c.translate(cx, h / 2);
    c.rotate(pi / 2);
    _text(
      c,
      'END ZONE',
      Offset.zero,
      26,
      Colors.white.withValues(alpha: .85),
      bold: true,
      spacing: 6,
    );
    c.restore();
  }

  void _baselineLabel(Canvas c, double cx, double h) {
    c.save();
    c.translate(cx, h / 2);
    c.rotate(pi / 2);
    _text(
      c,
      'DRAFT DASH',
      Offset.zero,
      22,
      Colors.white.withValues(alpha: .9),
      bold: true,
      spacing: 4,
    );
    c.restore();
  }

  void _text(
    Canvas c,
    String s,
    Offset center,
    double size,
    Color color, {
    bool bold = false,
    double spacing = 0,
  }) {
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
