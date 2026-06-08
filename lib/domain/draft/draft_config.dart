import 'participant.dart';
import 'draft_mode.dart';
import 'league_ledger.dart';

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

  /// Season-long commissioner notes, odds modifiers, and pick locks.
  final List<LeagueLedgerEntry> ledgerEntries;

  const DraftConfig({
    required this.participants,
    this.mode = DraftMode.race,
    this.weightingEnabled = true,
    this.reverseOrder = false,
    this.pins = const {},
    this.lotteryPickCount,
    this.ledgerEntries = const [],
  });

  int get size => participants.length;

  int get effectiveLotteryPickCount {
    if (size <= 1) return 0;
    return (lotteryPickCount ?? size - 1).clamp(0, size - 1);
  }

  DraftConfig get ledgerApplied {
    if (ledgerEntries.isEmpty) return this;
    final adjustments = <String, double>{};
    final ledgerPins = <int, String>{};
    final validIds = {for (final p in participants) p.id};

    for (final entry in ledgerEntries) {
      if (!validIds.contains(entry.managerId)) continue;
      if (entry.affectsOdds) {
        adjustments[entry.managerId] =
            (adjustments[entry.managerId] ?? 0) + entry.weightDelta;
      }
      if (entry.locksPick) {
        final slot = entry.pickIndex!;
        if (slot >= 0 && slot < participants.length) {
          ledgerPins[slot] = entry.managerId;
        }
      }
    }

    return copyWith(
      participants: [
        for (final p in participants)
          p.copyWith(
            weight: (p.weight + (adjustments[p.id] ?? 0)).clamp(0.2, 5.0),
          ),
      ],
      pins: {...pins, ...ledgerPins},
    );
  }

  DraftConfig copyWith({
    List<Participant>? participants,
    DraftMode? mode,
    bool? weightingEnabled,
    bool? reverseOrder,
    Map<int, String>? pins,
    int? lotteryPickCount,
    List<LeagueLedgerEntry>? ledgerEntries,
  }) {
    return DraftConfig(
      participants: participants ?? this.participants,
      mode: mode ?? this.mode,
      weightingEnabled: weightingEnabled ?? this.weightingEnabled,
      reverseOrder: reverseOrder ?? this.reverseOrder,
      pins: pins ?? this.pins,
      lotteryPickCount: lotteryPickCount ?? this.lotteryPickCount,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
    );
  }

  Map<String, dynamic> toJson() => {
    'participants': [for (final p in participants) p.toJson()],
    'mode': mode.code,
    'weightingEnabled': weightingEnabled,
    'reverseOrder': reverseOrder,
    'pins': {for (final e in pins.entries) e.key.toString(): e.value},
    if (lotteryPickCount != null) 'lotteryPickCount': lotteryPickCount,
    if (ledgerEntries.isNotEmpty)
      'ledgerEntries': [for (final e in ledgerEntries) e.toJson()],
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
    ledgerEntries: [
      for (final e in ((j['ledgerEntries'] ?? []) as List))
        LeagueLedgerEntry.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
    pins: {
      for (final e in ((j['pins'] ?? {}) as Map).entries)
        int.parse(e.key as String): e.value as String,
    },
  );
}
