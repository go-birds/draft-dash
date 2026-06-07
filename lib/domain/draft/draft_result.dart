import 'draft_mode.dart';
import 'participant.dart';

/// The outcome of a draft: a final ordering of manager ids (index 0 == pick #1).
///
/// All four modes converge on this type. The auto-reveal modes precompute it
/// via `DraftEngine.generate`; the bidding mode builds it as picks are awarded.
class DraftResult {
  /// Manager ids in pick order. `order[0]` holds pick #1.
  final List<String> order;
  final int seed;
  final DraftMode mode;
  final DateTime createdAt;
  final String? leagueName;

  const DraftResult({
    required this.order,
    required this.seed,
    required this.mode,
    required this.createdAt,
    this.leagueName,
  });

  int get size => order.length;

  /// 1-based pick number for [participantId], or -1 if absent.
  int pickOf(String participantId) {
    final i = order.indexOf(participantId);
    return i < 0 ? -1 : i + 1;
  }

  /// Resolve the ordered ids back to [Participant]s using [roster].
  List<Participant> resolve(List<Participant> roster) {
    final byId = {for (final p in roster) p.id: p};
    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!
    ];
  }

  DraftResult copyWith({List<String>? order, String? leagueName}) => DraftResult(
        order: order ?? this.order,
        seed: seed,
        mode: mode,
        createdAt: createdAt,
        leagueName: leagueName ?? this.leagueName,
      );

  Map<String, dynamic> toJson() => {
        'order': order,
        'seed': seed,
        'mode': mode.code,
        'createdAt': createdAt.toIso8601String(),
        if (leagueName != null) 'leagueName': leagueName,
      };

  static DraftResult fromJson(Map<String, dynamic> j) => DraftResult(
        order: [for (final id in (j['order'] as List)) id as String],
        seed: (j['seed'] as num).toInt(),
        mode: DraftMode.fromCode((j['mode'] ?? 'race') as String),
        createdAt:
            DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
        leagueName: j['leagueName'] as String?,
      );
}
