import 'draft_config.dart';
import 'draft_mode.dart';
import 'league_ledger.dart';
import 'participant.dart';

/// One commissioner-authored change to the generated draft order.
///
/// Full before/after boards are retained instead of only the moved manager so
/// the audit trail remains unambiguous when several edits are made.
class DraftOrderEdit {
  final DateTime editedAt;
  final List<String> previousOrder;
  final List<String> updatedOrder;

  DraftOrderEdit({
    required this.editedAt,
    required List<String> previousOrder,
    required List<String> updatedOrder,
  }) : previousOrder = List<String>.unmodifiable(previousOrder),
       updatedOrder = List<String>.unmodifiable(updatedOrder);

  Map<String, dynamic> toJson() => {
    'editedAt': editedAt.toIso8601String(),
    'previousOrder': previousOrder,
    'updatedOrder': updatedOrder,
  };

  static DraftOrderEdit fromJson(Map<String, dynamic> json) => DraftOrderEdit(
    editedAt:
        DateTime.tryParse((json['editedAt'] ?? '') as String) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    previousOrder: [
      for (final id in ((json['previousOrder'] ?? const []) as List))
        id as String,
    ],
    updatedOrder: [
      for (final id in ((json['updatedOrder'] ?? const []) as List))
        id as String,
    ],
  );
}

/// Audit-friendly metadata captured when a draft is executed.
///
/// The short proof code stays compact and deterministic. This metadata keeps
/// the full settings snapshot that explains how that draft was run.
class DraftProofMetadata {
  final DateTime executedAt;
  final int seed;
  final DraftConfig settings;
  final List<DraftOrderEdit> orderEdits;

  DraftProofMetadata({
    required this.executedAt,
    required this.seed,
    required this.settings,
    List<DraftOrderEdit> orderEdits = const [],
  }) : orderEdits = List<DraftOrderEdit>.unmodifiable(orderEdits);

  factory DraftProofMetadata.fromConfig(
    DraftConfig settings, {
    required DateTime executedAt,
    required int seed,
  }) => DraftProofMetadata(
    executedAt: executedAt,
    seed: seed,
    settings: DraftConfig(
      participants: List<Participant>.unmodifiable(settings.participants),
      mode: settings.mode,
      weightingEnabled: settings.weightingEnabled,
      reverseOrder: settings.reverseOrder,
      pins: Map<int, String>.unmodifiable(settings.pins),
      lotteryPickCount: settings.lotteryPickCount,
      ledgerEntries: List<LeagueLedgerEntry>.unmodifiable(
        settings.ledgerEntries,
      ),
    ),
  );

  DraftProofMetadata copyWith({List<DraftOrderEdit>? orderEdits}) =>
      DraftProofMetadata(
        executedAt: executedAt,
        seed: seed,
        settings: settings,
        orderEdits: orderEdits ?? this.orderEdits,
      );

  Map<String, dynamic> toJson() => {
    'executedAt': executedAt.toIso8601String(),
    'seed': seed,
    'settings': settings.toJson(),
    if (orderEdits.isNotEmpty)
      'orderEdits': [for (final edit in orderEdits) edit.toJson()],
  };

  static DraftProofMetadata fromJson(Map<String, dynamic> j) =>
      DraftProofMetadata(
        executedAt:
            DateTime.tryParse((j['executedAt'] ?? '') as String) ??
            DateTime.now(),
        seed: (j['seed'] as num?)?.toInt() ?? 0,
        settings: DraftConfig.fromJson(
          Map<String, dynamic>.from((j['settings'] ?? const {}) as Map),
        ),
        orderEdits: [
          for (final edit in ((j['orderEdits'] ?? const []) as List))
            DraftOrderEdit.fromJson(Map<String, dynamic>.from(edit as Map)),
        ],
      );
}

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
  final List<Participant> rosterSnapshot;
  final DraftProofMetadata? proofMetadata;

  const DraftResult({
    required this.order,
    required this.seed,
    required this.mode,
    required this.createdAt,
    this.leagueName,
    this.rosterSnapshot = const [],
    this.proofMetadata,
  });

  int get size => order.length;

  String get proofCode {
    var hash = 0x811C9DC5;

    void mixByte(int value) {
      hash ^= value & 0xFF;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    void mixInt(int value) {
      for (var shift = 0; shift < 32; shift += 8) {
        mixByte(value >> shift);
      }
    }

    void mixString(String value) {
      for (final unit in value.codeUnits) {
        mixByte(unit);
        mixByte(unit >> 8);
      }
      mixByte(0x1F);
    }

    mixString(mode.code);
    mixInt(seed);
    for (final id in order) {
      mixString(id);
    }
    final edits = proofMetadata?.orderEdits ?? const <DraftOrderEdit>[];
    if (edits.isNotEmpty) {
      // Preserve legacy proof codes exactly for boards with no edit trail.
      mixString('commissioner-order-edits-v1');
      mixInt(edits.length);
      for (final edit in edits) {
        mixString(edit.editedAt.toUtc().toIso8601String());
        mixInt(edit.previousOrder.length);
        for (final id in edit.previousOrder) {
          mixString(id);
        }
        mixInt(edit.updatedOrder.length);
        for (final id in edit.updatedOrder) {
          mixString(id);
        }
      }
    }

    final body = hash.toRadixString(36).toUpperCase().padLeft(7, '0');
    return 'DD-${body.substring(0, 3)}-${body.substring(3)}';
  }

  /// 1-based pick number for [participantId], or -1 if absent.
  int pickOf(String participantId) {
    final i = order.indexOf(participantId);
    return i < 0 ? -1 : i + 1;
  }

  /// Resolve the ordered ids back to [Participant]s using [roster].
  List<Participant> resolve(List<Participant> roster) {
    final byId = {
      for (final p in rosterSnapshot) p.id: p,
      for (final p in roster) p.id: p,
    };
    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
  }

  DraftResult copyWith({
    List<String>? order,
    String? leagueName,
    List<Participant>? rosterSnapshot,
    DraftProofMetadata? proofMetadata,
  }) => DraftResult(
    order: order ?? this.order,
    seed: seed,
    mode: mode,
    createdAt: createdAt,
    leagueName: leagueName ?? this.leagueName,
    rosterSnapshot: rosterSnapshot ?? this.rosterSnapshot,
    proofMetadata: proofMetadata ?? this.proofMetadata,
  );

  Map<String, dynamic> toJson() => {
    'order': order,
    'seed': seed,
    'mode': mode.code,
    'createdAt': createdAt.toIso8601String(),
    if (leagueName != null) 'leagueName': leagueName,
    if (rosterSnapshot.isNotEmpty)
      'rosterSnapshot': [for (final p in rosterSnapshot) p.toJson()],
    if (proofMetadata != null) 'proofMetadata': proofMetadata!.toJson(),
  };

  static DraftResult fromJson(Map<String, dynamic> j) => DraftResult(
    order: [for (final id in (j['order'] as List)) id as String],
    seed: (j['seed'] as num).toInt(),
    mode: DraftMode.fromCode((j['mode'] ?? 'race') as String),
    createdAt:
        DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
    leagueName: j['leagueName'] as String?,
    rosterSnapshot: [
      for (final p in ((j['rosterSnapshot'] ?? []) as List))
        Participant.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
    proofMetadata: j['proofMetadata'] == null
        ? null
        : DraftProofMetadata.fromJson(
            Map<String, dynamic>.from(j['proofMetadata'] as Map),
          ),
  );
}
