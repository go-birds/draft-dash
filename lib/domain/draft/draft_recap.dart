import 'draft_mode.dart';
import 'draft_result.dart';
import 'participant.dart';

/// Builds a league-chat friendly recap of a completed draft board.
class DraftRecap {
  const DraftRecap._();

  static String formatShort({
    required DraftMode mode,
    required List<Participant> ordered,
    String? leagueName,
    String? proofCode,
  }) => _format(
    mode: mode,
    ordered: ordered,
    leagueName: leagueName,
    proofCode: proofCode,
    proofMetadata: null,
  );

  static String format({
    required DraftMode mode,
    required List<Participant> ordered,
    String? leagueName,
    String? proofCode,
    DraftProofMetadata? proofMetadata,
  }) => formatFull(
    mode: mode,
    ordered: ordered,
    leagueName: leagueName,
    proofCode: proofCode,
    proofMetadata: proofMetadata,
  );

  static String formatFull({
    required DraftMode mode,
    required List<Participant> ordered,
    String? leagueName,
    String? proofCode,
    DraftProofMetadata? proofMetadata,
  }) => _format(
    mode: mode,
    ordered: ordered,
    leagueName: leagueName,
    proofCode: proofCode,
    proofMetadata: proofMetadata,
  );

  static String _format({
    required DraftMode mode,
    required List<Participant> ordered,
    String? leagueName,
    String? proofCode,
    required DraftProofMetadata? proofMetadata,
  }) {
    final cleanLeague = leagueName?.trim();
    final title = cleanLeague == null || cleanLeague.isEmpty
        ? 'Draft Dash results'
        : '$cleanLeague draft results';
    final lines = <String>[title, 'Mode: ${mode.label}'];
    final cleanProof = proofCode?.trim();
    if (cleanProof != null && cleanProof.isNotEmpty) {
      lines.add('Proof code: $cleanProof');
    }
    if (proofMetadata != null) {
      lines.addAll(_proofMetadataLines(proofMetadata));
    }

    if (ordered.isNotEmpty) {
      lines.add('First overall: ${ordered.first.name}');
      lines.add('');
      lines.add('Draft board:');
      for (var i = 0; i < ordered.length; i++) {
        final manager = ordered[i];
        lines.add('${i + 1}. ${manager.name} (${manager.initials})');
      }
    }

    lines.add('');
    lines.add('Settled with Draft Dash');
    return lines.join('\n');
  }

  static List<String> proofExplainerLines({
    required String proofCode,
    DraftProofMetadata? proofMetadata,
  }) {
    final lines = <String>[
      'Proof code: $proofCode',
      'This proof code is a deterministic fingerprint of the draft mode, seed, and final pick order.',
    ];

    if (proofMetadata == null) {
      lines.add(
        'No verification details were saved with this board, so only the proof code is available.',
      );
      return lines;
    }

    final settings = proofMetadata.settings;
    final pins = settings.pins.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final managersById = {for (final p in settings.participants) p.id: p};
    final pinSummary = pins.isEmpty
        ? 'none'
        : [
            for (final e in pins)
              'pick ${e.key + 1}=${managersById[e.value]?.name ?? e.value}',
          ].join(', ');
    final ledgerSummary = settings.ledgerEntries.isEmpty
        ? 'none'
        : [
            for (final e in settings.ledgerEntries) e.summary(managersById),
          ].join(' | ');

    lines.add('Executed at: ${proofMetadata.executedAt.toIso8601String()}');
    lines.add('Seed: ${proofMetadata.seed}');
    lines.add(
      'Settings metadata: mode ${settings.mode.label}, weighting ${settings.weightingEnabled ? 'on' : 'off'}, reverse order ${settings.reverseOrder ? 'on' : 'off'}, lottery picks ${settings.effectiveLotteryPickCount}',
    );
    lines.add('Commissioner pins: $pinSummary');
    lines.add('League Ledger: $ledgerSummary');
    lines.addAll(_orderEditLines(proofMetadata));
    lines.add(
      'Manager settings: ${[for (final p in settings.participants) '${p.name} (${p.initials}, weight ${p.weight.toStringAsFixed(2)}, budget ${p.budget})'].join('; ')}',
    );
    return lines;
  }

  static List<String> _proofMetadataLines(DraftProofMetadata metadata) {
    final settings = metadata.settings;
    final pins = settings.pins.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final managersById = {for (final p in settings.participants) p.id: p};
    final pinSummary = pins.isEmpty
        ? 'none'
        : [
            for (final e in pins)
              'pick ${e.key + 1}=${managersById[e.value]?.name ?? e.value}',
          ].join(', ');
    final managerSummary = [
      for (final p in settings.participants)
        '${p.name} (${p.initials}, weight ${p.weight.toStringAsFixed(2)}, '
            'budget ${p.budget})',
    ].join('; ');
    final ledgerSummary = settings.ledgerEntries.isEmpty
        ? 'none'
        : [
            for (final e in settings.ledgerEntries) e.summary(managersById),
          ].join(' | ');

    return [
      'Executed: ${metadata.executedAt.toIso8601String()}',
      'Seed: ${metadata.seed}',
      'Settings: mode ${settings.mode.label}, '
          'weighting ${settings.weightingEnabled ? 'on' : 'off'}, '
          'reverse order ${settings.reverseOrder ? 'on' : 'off'}, '
          'lottery picks ${settings.effectiveLotteryPickCount}',
      'Commissioner pins: $pinSummary',
      'League Ledger: $ledgerSummary',
      ..._orderEditLines(metadata),
      'Manager settings: $managerSummary',
    ];
  }

  static List<String> _orderEditLines(DraftProofMetadata metadata) {
    if (metadata.orderEdits.isEmpty) {
      return const ['Commissioner edits: none'];
    }
    final managersById = {
      for (final p in metadata.settings.participants) p.id: p,
    };
    return [
      'Commissioner edits: ${metadata.orderEdits.length}',
      for (var i = 0; i < metadata.orderEdits.length; i++)
        'Edit ${i + 1} at ${metadata.orderEdits[i].editedAt.toUtc().toIso8601String()}: '
            '${_namedOrder(metadata.orderEdits[i].previousOrder, managersById)} → '
            '${_namedOrder(metadata.orderEdits[i].updatedOrder, managersById)}',
    ];
  }

  static String _namedOrder(
    List<String> order,
    Map<String, Participant> managersById,
  ) => [
    for (var i = 0; i < order.length; i++)
      '${i + 1}. ${managersById[order[i]]?.name ?? order[i]}',
  ].join(', ');
}
