import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../domain/draft/participant.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _race;
  late final List<Participant> _lineup; // lane order (roster order)
  final Map<String, double> _finish =
      {}; // id -> fraction of race when it finishes
  late final int _n;

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
          duration: Duration(milliseconds: 5200 + _n * 200),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) _onFinish();
        });

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
      body: AnimatedBuilder(
        animation: _race,
        builder: (context, _) {
          final t = _racing ? _race.value : 0.0;
          // current progress per participant
          final prog = {for (final p in _lineup) p.id: _progressFor(p.id, t)};
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
                stride: _racing ? t * 42 + i * .8 : 0,
                leader: false,
              ),
          ];
          // leader = max progress
          String? leaderId;
          double best = -1;
          prog.forEach((id, v) {
            if (v > best) {
              best = v;
              leaderId = id;
            }
          });
          final runnersWithLeader = [
            for (var i = 0; i < runners.length; i++)
              _lineup[i].id == leaderId
                  ? RaceRunner(
                      color: runners[i].color,
                      number: runners[i].number,
                      progress: runners[i].progress,
                      stride: runners[i].stride,
                      leader: true,
                    )
                  : runners[i],
          ];

          final leader = _lineup.firstWhere(
            (p) => p.id == leaderId,
            orElse: () => _lineup.first,
          );
          final liveOrder = [..._lineup]
            ..sort((a, b) => prog[b.id]!.compareTo(prog[a.id]!));

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: FieldRacePainter(
                    runners: runnersWithLeader,
                    leaderProgress: leaderProgress,
                    tk: tk,
                  ),
                ),
              ),
              _Scoreboard(leader: leader, t: t),
              _OrderTicker(order: liveOrder),
              if (_countdown > -1 && !_racing) _Countdown(value: _countdown),
              if (_finished) _FinishFlash(winner: liveOrder.first),
            ],
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
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: tk.scoreboard.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tk.scoreboardLine),
          ),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tk.led,
                  boxShadow: [BoxShadow(color: tk.led, blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 8),
              Text('LIVE', style: tk.label.copyWith(fontSize: 13)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LEADER',
                      style: tk.label.copyWith(
                        fontSize: 10,
                        color: tk.textMuted,
                      ),
                    ),
                    Text(
                      '${leader.name.toUpperCase()} · #${leader.number}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tk.displayLarge.copyWith(
                        fontSize: 20,
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
                    style: tk.displayLarge.copyWith(fontSize: 22),
                  ),
                  Text(
                    'CLOCK',
                    style: tk.label.copyWith(fontSize: 9, color: tk.textMuted),
                  ),
                ],
              ),
            ],
          ),
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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
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
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final p = order[i];
                    final first = i == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
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
                          fontSize: 12,
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
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  final int value;
  const _Countdown({required this.value});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final label = value <= 0 ? 'GO!' : '$value';
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: .35),
        alignment: Alignment.center,
        child: Text(
          label,
          style: tk.displayLarge.copyWith(
            fontSize: value <= 0 ? 96 : 130,
            color: value <= 0 ? tk.led : tk.gold,
          ),
        ),
      ),
    );
  }
}

class _FinishFlash extends StatelessWidget {
  final Participant winner;
  const _FinishFlash({required this.winner});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: .45),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🏁 TOUCHDOWN',
              style: tk.label.copyWith(color: tk.gold, letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text(
              winner.name.toUpperCase(),
              style: tk.displayLarge.copyWith(fontSize: 46),
            ),
            Text('GETS PICK #1', style: tk.title.copyWith(color: tk.gold)),
          ],
        ),
      ),
    );
  }
}
