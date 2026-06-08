import 'participant.dart';
import 'draft_mode.dart';

/// Everything needed to run a draft: who's in it, the chosen mode, the odds
/// switch, ordering direction, and any commissioner pre-draw rigging.
class DraftConfig {
  final List<Participant> participants;
  final DraftMode mode;

  /// When false, every manager's [Participant.weight] is treated as 1.0 (even).
  final bool weightingEnabled;

  /// When true, the top weighted performer receives the *last* pick instead of
  /// the first (reverse-standings style). Pins are unaffected.
  final bool reverseOrder;

  /// Commissioner pre-draw rigging: pick index (0-based; 0 == pick #1) -> id.
  final Map<int, String> pins;

  /// Number of picks decided by NBA-style lottery combinations.
  ///
  /// Null means "draw until the last manager remains" (`size - 1`). Lower
  /// values leave more of the board to deterministic fill.
  final int? lotteryPickCount;

  const DraftConfig({
    required this.participants,
    this.mode = DraftMode.race,
    this.weightingEnabled = true,
    this.reverseOrder = false,
    this.pins = const {},
    this.lotteryPickCount,
  });

  int get size => participants.length;

  int get effectiveLotteryPickCount {
    if (size <= 1) return 0;
    return (lotteryPickCount ?? size - 1).clamp(0, size - 1);
  }

  DraftConfig copyWith({
    List<Participant>? participants,
    DraftMode? mode,
    bool? weightingEnabled,
    bool? reverseOrder,
    Map<int, String>? pins,
    int? lotteryPickCount,
  }) {
    return DraftConfig(
      participants: participants ?? this.participants,
      mode: mode ?? this.mode,
      weightingEnabled: weightingEnabled ?? this.weightingEnabled,
      reverseOrder: reverseOrder ?? this.reverseOrder,
      pins: pins ?? this.pins,
      lotteryPickCount: lotteryPickCount ?? this.lotteryPickCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'participants': [for (final p in participants) p.toJson()],
    'mode': mode.code,
    'weightingEnabled': weightingEnabled,
    'reverseOrder': reverseOrder,
    'pins': {for (final e in pins.entries) e.key.toString(): e.value},
    if (lotteryPickCount != null) 'lotteryPickCount': lotteryPickCount,
  };

  static DraftConfig fromJson(Map<String, dynamic> j) => DraftConfig(
    participants: [
      for (final p in (j['participants'] as List))
        Participant.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
    mode: DraftMode.fromCode((j['mode'] ?? 'race') as String),
    weightingEnabled: (j['weightingEnabled'] as bool?) ?? true,
    reverseOrder: (j['reverseOrder'] as bool?) ?? false,
    lotteryPickCount: (j['lotteryPickCount'] as num?)?.toInt(),
    pins: {
      for (final e in ((j['pins'] ?? {}) as Map).entries)
        int.parse(e.key as String): e.value as String,
    },
  );
}
