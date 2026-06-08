import 'participant.dart';

enum LedgerEntryType {
  oddsBoost('odds_boost', 'Odds boost'),
  oddsPenalty('odds_penalty', 'Odds penalty'),
  pickLock('pick_lock', 'Pick lock'),
  note('note', 'Note');

  final String code;
  final String label;
  const LedgerEntryType(this.code, this.label);

  static LedgerEntryType fromCode(String code) => values.firstWhere(
    (v) => v.code == code,
    orElse: () => LedgerEntryType.note,
  );
}

/// A commissioner-recorded season consequence that can affect draft day.
class LeagueLedgerEntry {
  final String id;
  final LedgerEntryType type;
  final String managerId;
  final String title;
  final String notes;
  final double weightDelta;

  /// 0-based pick index for pick locks/traded picks.
  final int? pickIndex;
  final DateTime createdAt;

  const LeagueLedgerEntry({
    required this.id,
    required this.type,
    required this.managerId,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.weightDelta = 0,
    this.pickIndex,
  });

  bool get affectsOdds =>
      type == LedgerEntryType.oddsBoost || type == LedgerEntryType.oddsPenalty;

  bool get locksPick => type == LedgerEntryType.pickLock && pickIndex != null;

  String summary(Map<String, Participant> managersById) {
    final manager = managersById[managerId]?.name ?? 'Unknown manager';
    return switch (type) {
      LedgerEntryType.oddsBoost =>
        '$manager odds boosted +${weightDelta.abs().toStringAsFixed(1)}x: $title',
      LedgerEntryType.oddsPenalty =>
        '$manager odds penalized -${weightDelta.abs().toStringAsFixed(1)}x: $title',
      LedgerEntryType.pickLock =>
        '$manager locked to pick #${(pickIndex ?? 0) + 1}: $title',
      LedgerEntryType.note => '$manager note: $title',
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.code,
    'managerId': managerId,
    'title': title,
    'notes': notes,
    'weightDelta': weightDelta,
    if (pickIndex != null) 'pickIndex': pickIndex,
    'createdAt': createdAt.toIso8601String(),
  };

  static LeagueLedgerEntry fromJson(Map<String, dynamic> j) =>
      LeagueLedgerEntry(
        id: (j['id'] ?? '') as String,
        type: LedgerEntryType.fromCode((j['type'] ?? 'note') as String),
        managerId: (j['managerId'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        notes: (j['notes'] ?? '') as String,
        weightDelta: (j['weightDelta'] as num?)?.toDouble() ?? 0,
        pickIndex: (j['pickIndex'] as num?)?.toInt(),
        createdAt:
            DateTime.tryParse((j['createdAt'] ?? '') as String) ??
            DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      other is LeagueLedgerEntry &&
      other.id == id &&
      other.type == type &&
      other.managerId == managerId &&
      other.title == title &&
      other.notes == notes &&
      other.weightDelta == weightDelta &&
      other.pickIndex == pickIndex &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    managerId,
    title,
    notes,
    weightDelta,
    pickIndex,
    createdAt,
  );
}
