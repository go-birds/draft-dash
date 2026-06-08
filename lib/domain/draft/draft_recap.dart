import 'draft_mode.dart';
import 'participant.dart';

/// Builds a league-chat friendly recap of a completed draft board.
class DraftRecap {
  const DraftRecap._();

  static String format({
    required DraftMode mode,
    required List<Participant> ordered,
    String? leagueName,
    String? proofCode,
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
}
