import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/nba_lottery.dart';
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
    with TickerProviderStateMixin {
  late final AnimationController _tumble;
  late final AnimationController _selectedBallFlight;
  int _roundIndex = 0;
  int _ballsDrawn = 0;
  int? _pendingBall;

  @override
  void initState() {
    super.initState();
    _tumble = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _selectedBallFlight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
  }

  @override
  void dispose() {
    _tumble.dispose();
    _selectedBallFlight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final result = ref.watch(draftControllerProvider);
    final cfg = ref.watch(draftConfigProvider);
    final byId = {for (final p in cfg.participants) p.id: p};
    final plan = result == null
        ? null
        : NbaLottery.generate(cfg, seed: result.seed);
    final rounds = plan?.rounds ?? const <NbaLotteryRound>[];
    final currentRound = _roundIndex < rounds.length
        ? rounds[_roundIndex]
        : null;
    final completedRounds = rounds.take(_roundIndex).toList();
    final alreadyWon = {for (final r in completedRounds) r.winnerId};
    final drawnBalls = currentRound == null
        ? const <int>[]
        : currentRound.balls.take(_ballsDrawn).toList();
    final chances =
        plan?.assignment.chancesAfter(
          drawnBalls: drawnBalls,
          alreadyWon: alreadyWon,
        ) ??
        const <String, double>{};
    final lotteryDone = _roundIndex >= rounds.length;
    final justWon = _ballsDrawn >= NbaLottery.ballsPerDraw
        ? byId[currentRound?.winnerId]
        : null;
    final shownWinners = [
      for (final r in completedRounds)
        if (byId[r.winnerId] != null) byId[r.winnerId]!,
      ?justWon,
    ];
    final possibleIds = {
      for (final e in chances.entries)
        if (e.value > 0) e.key,
    };
    final ballLabel = currentRound == null
        ? null
        : 'BALL ${min(_ballsDrawn + 1, NbaLottery.ballsPerDraw)} OF ${NbaLottery.ballsPerDraw}';
    final statusLabel = currentRound == null
        ? null
        : justWon == null
        ? 'LIVE ODDS'
        : 'PICK ${_roundIndex + 1} LOCKED';
    final statusText = currentRound == null
        ? null
        : justWon == null
        ? 'Update after every ball.'
        : 'Winning combo ${currentRound.balls.join('-')}';

    Future<void> drawNext() async {
      if (currentRound == null || _pendingBall != null) return;
      if (_ballsDrawn >= NbaLottery.ballsPerDraw) {
        setState(() {
          _roundIndex += 1;
          _ballsDrawn = 0;
        });
        return;
      }
      AppFeedback.of(ref).ballDraw();
      final nextBall = currentRound.balls[_ballsDrawn];
      setState(() => _pendingBall = nextBall);
      await _selectedBallFlight.forward(from: 0);
      if (!mounted) return;
      setState(() {
        _ballsDrawn += 1;
        _pendingBall = null;
      });
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
              lotteryDone ? 'THE BOARD IS SET' : 'PING-PONG DRAW',
              style: tk.displayLarge.copyWith(fontSize: 28),
            ),
            Text(
              lotteryDone
                  ? 'top ${rounds.length} picks drawn · full board ready'
                  : '14 balls · 4-number combo · pick ${_roundIndex + 1}',
              style: tk.label.copyWith(fontSize: 11, color: tk.textMuted),
            ),
            const SizedBox(height: 6),

            // machine
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _tumble,
                  builder: (_, child) => AnimatedBuilder(
                    animation: _selectedBallFlight,
                    builder: (_, _) => SizedBox(
                      width: 300,
                      height: 320,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            painter: _MachinePainter(tk: tk),
                            child: _BallField(
                              t: _tumble.value,
                              balls: [
                                for (var i = 1; i <= NbaLottery.ballCount; i++)
                                  i,
                              ],
                              drawnBalls: drawnBalls,
                              pendingBall: _pendingBall,
                              tk: tk,
                            ),
                          ),
                          if (_pendingBall != null)
                            _SelectedBallFlight(
                              ball: _pendingBall!,
                              progress: _selectedBallFlight.value,
                              tk: tk,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // drawn callout
            SizedBox(
              height: 96,
              child: currentRound == null
                  ? Center(
                      child: Text(
                        'Pick locked. Remaining teams fill the board.',
                        style: tk.body.copyWith(color: tk.textMuted),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < NbaLottery.ballsPerDraw; i++) ...[
                          LotteryBall(
                            color: i < drawnBalls.length
                                ? tk.gold
                                : tk.textMuted,
                            number: i < drawnBalls.length
                                ? '${drawnBalls[i]}'
                                : '?',
                            size: 48,
                            highlight: i == drawnBalls.length - 1,
                          ),
                          if (i != NbaLottery.ballsPerDraw - 1)
                            const SizedBox(width: 7),
                        ],
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                statusLabel!,
                                key: ValueKey(statusLabel),
                                style: tk.label.copyWith(
                                  fontSize: 11,
                                  color: tk.textMuted,
                                ),
                              ),
                            ),
                            Text(
                              justWon?.name.toUpperCase() ?? ballLabel!,
                              style: tk.displayLarge.copyWith(fontSize: 28),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                '$statusLabel · $statusText',
                                key: ValueKey('$statusLabel · $statusText'),
                                style: tk.body.copyWith(
                                  fontSize: 12,
                                  color: justWon == null
                                      ? tk.textMuted
                                      : tk.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            SizedBox(
              height: 136,
              child: _ProbabilityBoard(
                participants: cfg.participants,
                chances: chances,
                possibleIds: possibleIds,
                alreadyWon: alreadyWon,
                active: !lotteryDone,
                tk: tk,
              ),
            ),

            // mini board
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: shownWinners.length,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = shownWinners[i];
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
              child: lotteryDone
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
                      _ballsDrawn >= NbaLottery.ballsPerDraw
                          ? _roundIndex + 1 >= rounds.length
                                ? 'PICK LOCKED ✓'
                                : 'NEXT PICK'
                          : 'DRAW BALL ${_ballsDrawn + 1} OF ${NbaLottery.ballsPerDraw} 🎱',
                      onPressed: drawNext,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbabilityBoard extends StatelessWidget {
  final List<Participant> participants;
  final Map<String, double> chances;
  final Set<String> possibleIds;
  final Set<String> alreadyWon;
  final bool active;
  final DraftTokens tk;

  const _ProbabilityBoard({
    required this.participants,
    required this.chances,
    required this.possibleIds,
    required this.alreadyWon,
    required this.active,
    required this.tk,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Center(
        child: Text(
          'Pick locked. Remaining teams fill the board.',
          textAlign: TextAlign.center,
          style: tk.body.copyWith(color: tk.textMuted, fontSize: 12),
        ),
      );
    }
    final sorted = [...participants]
      ..sort((a, b) => (chances[b.id] ?? 0).compareTo(chances[a.id] ?? 0));
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: sorted.length,
      separatorBuilder: (_, i) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final p = sorted[i];
        final won = alreadyWon.contains(p.id);
        final chance = chances[p.id] ?? 0;
        final possible = possibleIds.contains(p.id) && !won;
        final dim = won || !possible;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: dim ? .32 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: tk.surface.withValues(alpha: dim ? .55 : 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: possible ? Color(p.colorValue) : tk.scoreboardLine,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(p.colorValue),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tk.body.copyWith(fontSize: 12),
                  ),
                ),
                Text(
                  won ? 'won' : '${(chance * 100).toStringAsFixed(1)}%',
                  style: tk.mono.copyWith(
                    fontSize: 11,
                    color: possible ? tk.led : tk.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
  final List<int> balls;
  final List<int> drawnBalls;
  final int? pendingBall;
  final DraftTokens tk;
  const _BallField({
    required this.t,
    required this.balls,
    required this.drawnBalls,
    required this.pendingBall,
    required this.tk,
  });

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
              if (balls[i] != pendingBall)
                _positioned(i, balls.length, cx, cy, r, balls[i]),
          ],
        );
      },
    );
  }

  Widget _positioned(int i, int n, double cx, double cy, double r, int ball) {
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
      child: LotteryBall(
        color: drawnBalls.contains(ball) ? tk.gold : tk.accent,
        number: '$ball',
        size: s,
        highlight: drawnBalls.contains(ball),
      ),
    );
  }
}

class _SelectedBallFlight extends StatelessWidget {
  final int ball;
  final double progress;
  final DraftTokens tk;

  const _SelectedBallFlight({
    required this.ball,
    required this.progress,
    required this.tk,
  });

  @override
  Widget build(BuildContext context) {
    final lift = Curves.easeOutCubic.transform((progress / .42).clamp(0, 1));
    final expand = Curves.easeOutBack.transform(
      ((progress - .28) / .34).clamp(0, 1),
    );
    final drop = Curves.easeInCubic.transform(
      ((progress - .58) / .42).clamp(0, 1),
    );
    final x = 150.0;
    final y = _lerp(182, 24, lift) + drop * 132;
    final size = _lerp(44, 86, expand) - drop * 24;
    final opacity = progress > .92 ? (1 - progress) / .08 : 1.0;

    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: LotteryBall(
          color: tk.gold,
          number: '$ball',
          size: size,
          highlight: true,
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
