import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/participant.dart';
import '../../services/feedback.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/lottery_ball.dart';
import 'result_screen.dart';

/// Weighted lottery: a glass machine of ping-pong balls; draw one per pick.
class LotteryScreen extends ConsumerStatefulWidget {
  const LotteryScreen({super.key});

  @override
  ConsumerState<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends ConsumerState<LotteryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tumble;
  int _drawn = 0;

  @override
  void initState() {
    super.initState();
    _tumble = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _tumble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final result = ref.watch(draftControllerProvider);
    final cfg = ref.watch(draftConfigProvider);
    final odds = ref.watch(oddsProvider);
    final byId = {for (final p in cfg.participants) p.id: p};
    final order = result?.order ?? const [];
    final picks = [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
    final n = picks.length;
    final drawnList = picks.take(_drawn).toList();
    final remaining = picks.skip(_drawn).toList();
    final allDone = _drawn >= n;
    final justDrawn = _drawn > 0 ? picks[_drawn - 1] : null;

    void drawNext() {
      if (_drawn >= n) return;
      AppFeedback.of(ref).ballDraw();
      setState(() => _drawn += 1);
    }

    return Scaffold(
      backgroundColor: tk.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'DRAFT LOTTERY',
              style: tk.label.copyWith(color: tk.gold, letterSpacing: 4),
            ),
            Text(
              allDone ? 'THE BOARD IS SET' : 'THE DRAW',
              style: tk.displayLarge.copyWith(fontSize: 28),
            ),
            Text(
              allDone
                  ? 'all $n picks drawn'
                  : 'weighted by odds · pick ${_drawn + 1} on the clock',
              style: tk.label.copyWith(fontSize: 11, color: tk.textMuted),
            ),
            const SizedBox(height: 6),

            // machine
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _tumble,
                  builder: (_, child) => SizedBox(
                    width: 300,
                    height: 320,
                    child: CustomPaint(
                      painter: _MachinePainter(tk: tk),
                      child: _BallField(
                        t: _tumble.value,
                        balls: remaining,
                        tk: tk,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // drawn callout
            SizedBox(
              height: 84,
              child: justDrawn == null
                  ? Center(
                      child: Text(
                        'Tap draw to start the lottery',
                        style: tk.body.copyWith(color: tk.textMuted),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LotteryBall(
                          color: Color(justDrawn.colorValue),
                          number: justDrawn.number,
                          size: 60,
                          highlight: true,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PICK $_drawn',
                              style: tk.label.copyWith(
                                fontSize: 11,
                                color: tk.textMuted,
                              ),
                            ),
                            Text(
                              justDrawn.name.toUpperCase(),
                              style: tk.displayLarge.copyWith(fontSize: 28),
                            ),
                            Text(
                              '${((odds[justDrawn.id] ?? 0) * 100).round()}% odds · on the board',
                              style: tk.body.copyWith(
                                fontSize: 12,
                                color: tk.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // mini board
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: drawnList.length,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = drawnList[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: tk.surfaceElevated,
                      border: Border.all(
                        color: i == 0 ? tk.gold : tk.scoreboardLine,
                      ),
                    ),
                    child: Text(
                      '${i + 1} ${p.name}',
                      style: tk.body.copyWith(
                        fontSize: 12,
                        color: i == 0 ? tk.gold : tk.textPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: allDone
                  ? PrimaryButton(
                      'SEE THE BOARD ✓',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const ResultScreen(),
                          ),
                        );
                      },
                    )
                  : PrimaryButton(
                      'DRAW PICK ${_drawn + 1} 🎱',
                      onPressed: drawNext,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MachinePainter extends CustomPainter {
  final DraftTokens tk;
  _MachinePainter({required this.tk});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 4);
    final r = size.width / 2 - 6;

    // pedestal
    final pedestal = Paint()..color = const Color(0xFF1A2029);
    final path = Path()
      ..moveTo(c.dx - 30, size.height - 14)
      ..lineTo(c.dx + 30, size.height - 14)
      ..lineTo(c.dx + 50, size.height)
      ..lineTo(c.dx - 50, size.height)
      ..close();
    canvas.drawPath(path, pedestal);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(c.dx, size.height - 4),
        width: 44,
        height: 5,
      ),
      Paint()..color = tk.whistle.withValues(alpha: .85),
    );

    // glass sphere
    final glass = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: .28),
          const Color(0xFF96BEEB).withValues(alpha: .10),
          const Color(0xFF0A1423).withValues(alpha: .55),
        ],
        stops: const [0, .4, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, glass);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFBED7FF).withValues(alpha: .35),
    );

    // top extraction tube
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - r - 4),
          width: 40,
          height: 70,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.white.withValues(alpha: .12),
    );

    // glass highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx - r * 0.35, c.dy - r * 0.45),
        width: r * 0.7,
        height: r * 0.45,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: .25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_MachinePainter old) => false;
}

class _BallField extends StatelessWidget {
  final double t;
  final List<Participant> balls;
  final DraftTokens tk;
  const _BallField({required this.t, required this.balls, required this.tk});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final cx = w / 2, cy = h / 2 + 4;
        final r = w / 2 - 40;
        return Stack(
          children: [
            for (var i = 0; i < balls.length; i++)
              _positioned(i, balls.length, cx, cy, r, balls[i]),
          ],
        );
      },
    );
  }

  Widget _positioned(
    int i,
    int n,
    double cx,
    double cy,
    double r,
    Participant p,
  ) {
    // distribute around a jittering ring, biased toward the lower half
    final baseAngle = (i / max(n, 1)) * 2 * pi;
    final wob = sin(t * 2 * pi + i * 1.7);
    final wob2 = cos(t * 2 * pi * 1.3 + i);
    final rad = r * (0.45 + 0.4 * ((i % 3) / 2)) + wob * 8;
    final angle = baseAngle + wob2 * 0.5 + t * 2 * pi * 0.15;
    final x = cx + cos(angle) * rad * 0.9;
    final y = cy + sin(angle) * rad * 0.6 + 18 + wob2 * 6;
    const s = 44.0;
    return Positioned(
      left: x - s / 2,
      top: y - s / 2,
      child: LotteryBall(color: Color(p.colorValue), number: p.number, size: s),
    );
  }
}
