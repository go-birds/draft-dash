import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft/participant.dart';
import '../../services/feedback.dart';
import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/jersey_chip.dart';
import 'result_screen.dart';

/// Live ColemanBucks auction. Pass-the-phone sealed bids per pick, then reveal.
class BiddingScreen extends ConsumerStatefulWidget {
  const BiddingScreen({super.key});

  @override
  ConsumerState<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends ConsumerState<BiddingScreen> {
  final Map<String, int> _bids = {}; // this round's locked bids
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final state = ref.watch(auctionProvider);
    if (state == null) {
      return Scaffold(
        backgroundColor: tk.background,
        body: Center(child: Text('No auction', style: tk.body)),
      );
    }

    final pickNo = state.currentPick + 1;
    final remaining = state.remainingManagers;

    if (_revealed) {
      return _RevealView(
        bids: _bids,
        onNext: () {
          if (state.isComplete) {
            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                builder: (_) => const ResultScreen()));
          } else {
            setState(() {
              _bids.clear();
              _revealed = false;
            });
          }
        },
      );
    }

    final allIn = _bids.length == remaining.length;

    return Scaffold(
      backgroundColor: tk.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text('💰 COLEMANBUCKS AUCTION',
                style: tk.label.copyWith(color: tk.gold, letterSpacing: 3)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('PICK ', style: tk.displayLarge.copyWith(fontSize: 28)),
                Text('#$pickNo',
                    style: tk.displayLarge.copyWith(fontSize: 28, color: tk.gold)),
                Text(' ON THE BLOCK',
                    style: tk.displayLarge.copyWith(fontSize: 28)),
              ],
            ),
            Text('pass the phone · enter sealed bids',
                style: tk.label.copyWith(fontSize: 11, color: tk.textMuted)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                itemCount: remaining.length,
                itemBuilder: (_, i) {
                  final p = remaining[i];
                  final locked = _bids.containsKey(p.id);
                  return _BidderRow(
                    p: p,
                    budget: state.budgetOf(p.id),
                    locked: locked,
                    onTap: () => _enterBid(context, p, state.budgetOf(p.id)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: PrimaryButton(
                allIn ? 'REVEAL BIDS 👀' : 'ALL MANAGERS MUST BID (${_bids.length}/${remaining.length})',
                onPressed: allIn ? _reveal : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reveal() {
    AppFeedback.of(ref).award();
    ref.read(auctionProvider.notifier).resolveRound(_bids);
    setState(() => _revealed = true);
  }

  Future<void> _enterBid(BuildContext context, Participant p, int budget) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.tokens.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _BidSheet(p: p, budget: budget),
    );
    if (result != null) {
      AppFeedback.of(ref).tap();
      setState(() => _bids[p.id] = result);
    }
  }
}

class _BidderRow extends StatelessWidget {
  final Participant p;
  final int budget;
  final bool locked;
  final VoidCallback onTap;

  const _BidderRow({
    required this.p,
    required this.budget,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tk.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: locked ? tk.led : tk.scoreboardLine),
        ),
        child: Row(
          children: [
            JerseyChip(color: Color(p.colorValue), number: p.number, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: tk.title.copyWith(fontSize: 17)),
                  Text('💰 $budget CB',
                      style: tk.body.copyWith(fontSize: 12, color: tk.textMuted)),
                ],
              ),
            ),
            if (locked)
              Row(
                children: [
                  Icon(Icons.lock, size: 16, color: tk.led),
                  const SizedBox(width: 6),
                  Text('BID IN',
                      style: tk.label.copyWith(fontSize: 12, color: tk.led)),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tk.gold),
                ),
                child: Text('TAP TO BID',
                    style: tk.label.copyWith(fontSize: 11, color: tk.gold)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BidSheet extends StatefulWidget {
  final Participant p;
  final int budget;
  const _BidSheet({required this.p, required this.budget});

  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  late int _bid = 0;

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final max = widget.budget;
    return Padding(
      padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: tk.textMuted,
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 16),
          JerseyChip(
              color: Color(widget.p.colorValue),
              number: widget.p.number,
              size: 56),
          const SizedBox(height: 8),
          Text(widget.p.name.toUpperCase(),
              style: tk.displayLarge.copyWith(fontSize: 24)),
          Text('keep it secret · budget $max CB',
              style: tk.body.copyWith(fontSize: 12, color: tk.textMuted)),
          const SizedBox(height: 18),
          Text('$_bid',
              style: tk.displayLarge.copyWith(fontSize: 64, color: tk.gold)),
          Text('ColemanBucks', style: tk.label.copyWith(color: tk.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              _step(tk, '-10', () => _set(_bid - 10)),
              const SizedBox(width: 8),
              _step(tk, '-1', () => _set(_bid - 1)),
              Expanded(
                child: Slider(
                  value: _bid.toDouble().clamp(0, max.toDouble()),
                  max: max.toDouble().clamp(1, double.infinity),
                  activeColor: tk.gold,
                  onChanged: (v) => setState(() => _bid = v.round()),
                ),
              ),
              _step(tk, '+1', () => _set(_bid + 1)),
              const SizedBox(width: 8),
              _step(tk, '+10', () => _set(_bid + 10)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: GhostButton('PASS (0)',
                    onPressed: () => Navigator.pop(context, 0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton('LOCK IN BID 🔒',
                    onPressed: () => Navigator.pop(context, _bid)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _set(int v) => setState(() => _bid = v.clamp(0, widget.budget));

  Widget _step(DraftTokens tk, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tk.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: tk.body.copyWith(fontWeight: FontWeight.w700)),
        ),
      );
}

class _RevealView extends ConsumerWidget {
  final Map<String, int> bids;
  final VoidCallback onNext;
  const _RevealView({required this.bids, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final state = ref.watch(auctionProvider)!;
    final cfg = ref.watch(draftConfigProvider);
    final byId = {for (final p in cfg.participants) p.id: p};

    final winnerId = state.assignedPicks.last;
    final winner = byId[winnerId]!;
    final paid = bids[winnerId] ?? 0;
    final pickNo = state.assignedPicks.length;

    // sort bids high→low for the reveal list
    final entries = bids.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: tk.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text('SEALED BIDS REVEALED',
                style: tk.label.copyWith(color: tk.gold, letterSpacing: 3)),
            Text('PICK #$pickNo', style: tk.displayLarge.copyWith(fontSize: 26)),
            const SizedBox(height: 10),
            // winner banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tk.scoreboard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tk.gold),
              ),
              child: Row(
                children: [
                  JerseyChip(
                      color: Color(winner.colorValue),
                      number: winner.number,
                      size: 54,
                      highlight: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${winner.name.toUpperCase()} WINS',
                            style: tk.displayLarge.copyWith(fontSize: 22)),
                        Text('paid $paid CB · ${state.budgetOf(winnerId)} left',
                            style: tk.body.copyWith(
                                fontSize: 12, color: tk.textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('$paid',
                          style: tk.displayLarge
                              .copyWith(fontSize: 30, color: tk.gold)),
                      Text('HIGH BID',
                          style: tk.label
                              .copyWith(fontSize: 9, color: tk.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                children: [
                  Text('THE BIDS',
                      style: tk.label.copyWith(color: tk.gold)),
                  const SizedBox(height: 8),
                  for (final e in entries)
                    _bidRow(tk, byId[e.key]!, e.value, e.key == winnerId,
                        state.budgetOf(e.key)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: PrimaryButton(
                state.isComplete
                    ? 'SEE THE BOARD ✓'
                    : 'AWARD & BID PICK #${pickNo + 1} ›',
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bidRow(
      DraftTokens tk, Participant p, int bid, bool winner, int balance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: winner ? tk.gold : tk.scoreboardLine),
      ),
      child: Row(
        children: [
          JerseyChip(color: Color(p.colorValue), number: p.number, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.name, style: tk.title.copyWith(fontSize: 16)),
                    if (winner)
                      Text('  ★ WINNER',
                          style: tk.label.copyWith(color: tk.gold, fontSize: 12)),
                  ],
                ),
                Text(bid == 0 ? 'passed' : 'balance $balance CB',
                    style: tk.body.copyWith(fontSize: 11.5, color: tk.textMuted)),
              ],
            ),
          ),
          Text(bid == 0 ? '—' : '$bid',
              style: tk.displayLarge.copyWith(
                  fontSize: 26, color: winner ? tk.gold : tk.textMuted)),
        ],
      ),
    );
  }
}
