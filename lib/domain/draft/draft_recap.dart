import 'draft_mode.dart';
import 'draft_result.dart';
import 'participant.dart';

/// Builds a league-chat friendly recap of a completed draft board.
class DraftRecap {
  const DraftRecap._();

  static String format({
    required DraftMode mode,
    required List<Participant> ordered,
    String? leagueName,
    String? proofCode,
    DraftProofMetadata? proofMetadata,
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
        lines.add('${i + 1}. ${manager.name} (#${manager.number})');
      }
    }

    lines.add('');
    lines.add('Settled with Draft Dash');
    return lines.join('\n');
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
        '${p.name} (#${p.number}, weight ${p.weight.toStringAsFixed(2)}, '
            'budget ${p.budget})',
    ].join('; ');

    return [
      'Executed: ${metadata.executedAt.toIso8601String()}',
      'Seed: ${metadata.seed}',
      'Settings: mode ${settings.mode.label}, '
          'weighting ${settings.weightingEnabled ? 'on' : 'off'}, '
          'reverse order ${settings.reverseOrder ? 'on' : 'off'}, '
          'lottery picks ${settings.effectiveLotteryPickCount}',
      'Commissioner pins: $pinSummary',
      'Manager settings: $managerSummary',
    ];
  }
}
