import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../domain/draft/participant.dart';
import '../../domain/draft/taunts.dart';
import '../../services/feedback.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/football_field.dart';
import 'result_screen.dart';

class RaceScreen extends ConsumerStatefulWidget {
  const RaceScreen({super.key});

  @override
  ConsumerState<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends ConsumerState<RaceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _race;
  late final AnimationController _intro;
  late final List<Participant> _lineup; // lane order (roster order)
  final Map<String, double> _finish =
      {}; // id -> fraction of race when it finishes
  late final int _n;
  late final String? _winnerId;
  late final int _seed;

  int _countdown = 3; // 3,2,1,0(GO)
  bool _racing = false;
  bool _finished = false;
  Timer? _countTimer;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    final cfg = ref.read(draftConfigProvider);
    final result = ref.read(draftControllerProvider);
    _lineup = cfg.participants;
    _n = _lineup.length;

    final order = result?.order ?? [for (final p in _lineup) p.id];
    _winnerId = order.isEmpty ? null : order.first;
    _seed = result?.seed ?? 0;
    final rand = Random(result?.seed ?? 1);
    double prev = 0;
    for (var r = 0; r < order.length; r++) {
      final base = order.length == 1
          ? 1.0
          : 0.82 + 0.18 * (r / (order.length - 1));
      var f = base + (rand.nextDouble() - 0.5) * 0.03;
      if (f <= prev + 0.012) f = prev + 0.012;
      _finish[order[r]] = f.clamp(0.0, 1.0);
      prev = _finish[order[r]]!;
    }
    if (order.isNotEmpty) _finish[order.last] = 1.0;

    _race =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 6400 + _n * 240),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) _onFinish();
        });
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _startCountdown();
  }

  void _startCountdown() {
    _countTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!mounted) return;
      setState(() => _countdown -= 1);
      if (_countdown <= 0) {
        t.cancel();
        AppFeedback.of(ref).whistle();
        setState(() => _racing = true);
        _race.forward();
      } else {
        AppFeedback.of(ref).countdownTick();
      }
    });
  }

  void _onFinish() {
    if (_finished) return;
    _finished = true;
    AppFeedback.of(ref).win();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ResultScreen()),
      );
    });
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _race.dispose();
    _intro.dispose();
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    super.dispose();
  }

  double _progressFor(String id, double t) {
    final f = _finish[id] ?? 1.0;
    // Mostly linear pacing so runners spread across the field; a tiny ease-in
    // gives a burst off the line. Reaches 1.0 exactly at t == f.
    final base = (t / f).clamp(0.0, 1.0);
    final p = 0.12 * Curves.easeIn.transform(base) + 0.88 * base;
    // suspense wobble that fades to zero by the finish (lead changes mid-race)
    final wob = 0.03 * sin(t * 8 + id.hashCode % 7) * (1 - t);
    return (p + wob).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Scaffold(
      backgroundColor: tk.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: Listenable.merge([_race, _intro]),
            builder: (context, _) {
              final t = _racing ? _race.value : 0.0;
              final introT = Curves.easeOutCubic.transform(
                _intro.value.clamp(0.0, 1.0),
              );
              // current progress per participant
              final prog = {
                for (final p in _lineup) p.id: _progressFor(p.id, t),
              };
              final leaderProgress = prog.values.fold<double>(
                0,
                (best, value) => value > best ? value : best,
              );
              final runners = [
                for (var i = 0; i < _n; i++)
                  RaceRunner(
                    color: Color(_lineup[i].colorValue),
                    number: _lineup[i].number,
                    progress: prog[_lineup[i].id]!,
                    stride: _racing ? t * 34 + i * .8 : 0,
                    leader: _racing && prog[_lineup[i].id]! == leaderProgress,
                    winner: _finished && _lineup[i].id == _winnerId,
                  ),
              ];

              final winner = _winnerId == null
                  ? null
                  : _lineup.firstWhere(
                      (p) => p.id == _winnerId,
                      orElse: () => _lineup.first,
                    );
              final leader = _lineup.firstWhere(
                (p) => prog[p.id] == leaderProgress,
                orElse: () => _lineup.first,
              );
              final liveOrder = [..._lineup]
                ..sort((a, b) => prog[b.id]!.compareTo(prog[a.id]!));

              final scoreboardWidth = min(constraints.maxWidth * .46, 360.0);
              final tickerWidth = min(constraints.maxWidth * .66, 640.0);
              final edgeInset = constraints.maxWidth > 900 ? 20.0 : 14.0;

              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: FieldRacePainter(
                        runners: runners,
                        leaderProgress: leaderProgress,
                        introProgress: introT,
                        racing: _racing,
                        finished: _finished,
                        tk: tk,
                      ),
                    ),
                  ),
                  Positioned(
                    left: edgeInset,
                    top: edgeInset,
                    width: scoreboardWidth,
                    child: _Scoreboard(leader: leader, t: t),
                  ),
                  Positioned(
                    right: edgeInset,
                    bottom: edgeInset,
                    width: tickerWidth,
                    child: _OrderTicker(order: liveOrder),
                  ),
                  if (_countdown > -1 && !_racing)
                    _Countdown(value: _countdown, introProgress: introT),
                  if (_finished)
                    _FinishFlash(
                      winner: winner ?? liveOrder.first,
                      taunt: tauntFor(
                        custom: (winner ?? liveOrder.first).taunt,
                        seed: _seed,
                        pickIndex: 0,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  final Participant leader;
  final double t;
  const _Scoreboard({required this.leader, required this.t});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final secs = (t * 6).toStringAsFixed(1);
    return SafeArea(
      bottom: false,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: tk.scoreboard.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tk.scoreboardLine),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tk.led,
                boxShadow: [BoxShadow(color: tk.led, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 7),
            Text('LIVE', style: tk.label.copyWith(fontSize: 12)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LEADER',
                    style: tk.label.copyWith(fontSize: 10, color: tk.textMuted),
                  ),
                  Text(
                    '${leader.name.toUpperCase()} · #${leader.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tk.displayLarge.copyWith(
                      fontSize: 18,
                      color: tk.gold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '0:${secs.padLeft(4, '0')}',
                  style: tk.displayLarge.copyWith(fontSize: 20),
                ),
                Text(
                  'CLOCK',
                  style: tk.label.copyWith(fontSize: 8, color: tk.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTicker extends StatelessWidget {
  final List<Participant> order;
  const _OrderTicker({required this.order});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
        decoration: BoxDecoration(
          color: tk.scoreboard.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tk.scoreboardLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RUNNING ORDER',
              style: tk.label.copyWith(fontSize: 10, color: tk.textMuted),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.length,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = order[i];
                  final first = i == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: tk.surfaceElevated,
                      border: Border.all(
                        color: first ? tk.gold : tk.scoreboardLine,
                      ),
                    ),
                    child: Text(
                      '${i + 1} · ${p.name}',
                      style: tk.body.copyWith(
                        fontSize: 11,
                        color: first ? tk.gold : tk.textPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  final int value;
  final double introProgress;
  const _Countdown({required this.value, required this.introProgress});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final label = value <= 0 ? 'GO!' : '$value';
    final banner = switch (value) {
      3 => 'LANES SET',
      2 => 'RUNNERS TO THE LINE',
      1 => 'READY ON YOUR MARK',
      _ => 'GO!',
    };
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.05),
            radius: .9,
            colors: [
              Colors.black.withValues(alpha: .18 + introProgress * .12),
              Colors.black.withValues(alpha: .42),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(banner, style: tk.label.copyWith(color: tk.textPrimary)),
            const SizedBox(height: 6),
            Text(
              label,
              style: tk.displayLarge.copyWith(
                fontSize: value <= 0 ? 96 : 130,
                color: value <= 0 ? tk.led : tk.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishFlash extends StatelessWidget {
  final Participant winner;
  final String taunt;
  const _FinishFlash({required this.winner, required this.taunt});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.05, -0.15),
            radius: 1.0,
            colors: [
              tk.gold.withValues(alpha: .28),
              Colors.black.withValues(alpha: .52),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PHOTO FINISH',
              style: tk.label.copyWith(color: tk.gold, letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: tk.scoreboard.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tk.gold, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: tk.gold.withValues(alpha: .32),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  winner.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: tk.displayLarge.copyWith(fontSize: 44, height: .95),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('CLAIMS PICK #1', style: tk.title.copyWith(color: tk.gold)),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 10),
                  child: child,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  '“$taunt”',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: tk.body.copyWith(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: tk.textPrimary.withValues(alpha: .85),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
