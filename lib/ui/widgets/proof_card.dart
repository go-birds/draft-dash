import 'package:flutter/material.dart';

import '../../domain/draft/draft_result.dart';
import '../../domain/draft/participant.dart';

/// A self-contained visual receipt that can be captured as a PNG.
///
/// Only public draft facts are rendered. Participant email addresses are
/// intentionally never accepted by this widget.
class ProofCard extends StatelessWidget {
  final DraftResult result;
  final List<Participant> ordered;

  const ProofCard({super.key, required this.result, required this.ordered});

  @override
  Widget build(BuildContext context) {
    final metadata = result.proofMetadata;
    final edits = metadata?.orderEdits ?? const <DraftOrderEdit>[];
    final managers = {
      for (final participant in ordered) participant.id: participant,
      if (metadata != null)
        for (final participant in metadata.settings.participants)
          participant.id: participant,
    };
    final league = result.leagueName?.trim();

    return Material(
      color: const Color(0xFF09111F),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF09111F),
          border: Border.all(color: const Color(0xFFE4B13D), width: 2),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFFF5F7FA),
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DRAFT DASH',
                style: TextStyle(
                  color: Color(0xFFE4B13D),
                  fontFamily: 'Anton',
                  fontSize: 32,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                league == null || league.isEmpty
                    ? 'VERIFIED DRAFT RECEIPT'
                    : '${league.toUpperCase()} • DRAFT RECEIPT',
                style: const TextStyle(
                  color: Color(0xFFAEB9C8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                color: const Color(0xFF132239),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROOF CODE',
                      style: TextStyle(
                        color: Color(0xFFAEB9C8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.proofCode,
                      key: const ValueKey('proof-card-code'),
                      style: const TextStyle(
                        color: Color(0xFF63E6BE),
                        fontFamily: 'JetBrainsMono',
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle('ORIGINAL EXECUTION'),
              if (metadata == null)
                const Text('Legacy board — execution metadata unavailable')
              else ...[
                _Fact(
                  'Executed',
                  metadata.executedAt.toUtc().toIso8601String(),
                ),
                _Fact('Seed', '${metadata.seed}'),
                _Fact('Mode', metadata.settings.mode.label),
                _Fact(
                  'Settings',
                  'weighting ${metadata.settings.weightingEnabled ? 'on' : 'off'} • '
                      'reverse ${metadata.settings.reverseOrder ? 'on' : 'off'} • '
                      'lottery picks ${metadata.settings.effectiveLotteryPickCount}',
                ),
              ],
              const SizedBox(height: 16),
              _SectionTitle('FINAL ORDER'),
              for (var i = 0; i < ordered.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '${i + 1}. ${ordered[i].name}',
                    style: TextStyle(
                      color: i == 0
                          ? const Color(0xFFE4B13D)
                          : const Color(0xFFF5F7FA),
                      fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              Container(
                key: const ValueKey('proof-card-edit-history'),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: edits.isEmpty
                      ? const Color(0xFF102B29)
                      : const Color(0xFF3B201D),
                  border: Border.all(
                    color: edits.isEmpty
                        ? const Color(0xFF63E6BE)
                        : const Color(0xFFFF8A65),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edits.isEmpty
                          ? 'ORIGINAL DRAW • NO COMMISSIONER EDITS'
                          : 'COMMISSIONER OVERRIDE • ${edits.length} ${edits.length == 1 ? 'EDIT' : 'EDITS'}',
                      style: TextStyle(
                        color: edits.isEmpty
                            ? const Color(0xFF63E6BE)
                            : const Color(0xFFFFAB91),
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                    for (var i = 0; i < edits.length; i++) ...[
                      const SizedBox(height: 10),
                      Text(
                        'EDIT ${i + 1} • ${edits[i].editedAt.toUtc().toIso8601String()}',
                        style: const TextStyle(
                          color: Color(0xFFFFCCBC),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'BEFORE  ${_orderLabel(edits[i].previousOrder, managers)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'AFTER   ${_orderLabel(edits[i].updatedOrder, managers)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'The proof code commits to the final order and every edit above. '
                'This receipt is an integrity record, not a cryptographic signature.',
                style: TextStyle(color: Color(0xFFAEB9C8), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _orderLabel(
    List<String> order,
    Map<String, Participant> managers,
  ) => [
    for (var i = 0; i < order.length; i++)
      '${i + 1}.${managers[order[i]]?.name ?? order[i]}',
  ].join('  ');
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFE4B13D),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Color(0xFFAEB9C8),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}
