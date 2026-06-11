/// A league manager taking part in the draft.
///
/// Pure data — no Flutter imports. [colorValue] is a 32-bit ARGB int so the
/// domain stays UI-agnostic; the UI converts it to a `Color`.
class Participant {
  final String id;
  final String name;

  /// Jersey number shown on the chip/sprite, e.g. "07".
  final String number;

  /// 32-bit ARGB color for this manager's jersey/chip.
  final int colorValue;

  /// Odds multiplier for the auto-reveal modes (race/cards/lottery).
  /// 1.0 = even. Higher = better chance at an early pick.
  final double weight;

  /// Starting ColemanBucks budget for the Bidding/Auction mode.
  final int budget;

  /// Optional walk-up line shown when this manager's pick is revealed.
  final String? taunt;

  const Participant({
    required this.id,
    required this.name,
    required this.number,
    required this.colorValue,
    this.weight = 1.0,
    this.budget = 100,
    this.taunt,
  });

  /// Sentinel so [copyWith] can distinguish "leave taunt alone" from
  /// "clear taunt to null".
  static const Object _unsetTaunt = Object();

  Participant copyWith({
    String? id,
    String? name,
    String? number,
    int? colorValue,
    double? weight,
    int? budget,
    Object? taunt = _unsetTaunt,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      colorValue: colorValue ?? this.colorValue,
      weight: weight ?? this.weight,
      budget: budget ?? this.budget,
      taunt: identical(taunt, _unsetTaunt) ? this.taunt : taunt as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'color': colorValue,
    'weight': weight,
    'budget': budget,
    if (taunt != null) 'taunt': taunt,
  };

  static Participant fromJson(Map<String, dynamic> j) => Participant(
    id: j['id'] as String,
    name: j['name'] as String,
    number: (j['number'] ?? '') as String,
    colorValue: (j['color'] as num).toInt(),
    weight: (j['weight'] as num?)?.toDouble() ?? 1.0,
    budget: (j['budget'] as num?)?.toInt() ?? 100,
    taunt: j['taunt'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is Participant &&
      other.id == id &&
      other.name == name &&
      other.number == number &&
      other.colorValue == colorValue &&
      other.weight == weight &&
      other.budget == budget &&
      other.taunt == taunt;

  @override
  int get hashCode =>
      Object.hash(id, name, number, colorValue, weight, budget, taunt);
}
