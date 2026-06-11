/// Walk-up lines shown when a pick is revealed.
///
/// Pure data — no Flutter imports. A manager's custom [Participant.taunt]
/// wins; otherwise a default line is chosen deterministically from the draft
/// seed so replays of the same draft show the same lines.
library;

const kDefaultTaunts = <String>[
  'Built different.',
  'Scoreboard.',
  'Dynasty starts now.',
  'Saw that coming.',
  'All gas, no brakes.',
  'The film never lies.',
  'Champagne in the group chat.',
  'Respect the process.',
  'Lucky? Call it destiny.',
  'First of many wins.',
  'Draft night legend.',
  'Take notes, league.',
];

/// The taunt line to show for the pick at [pickIndex] (0-based).
///
/// Returns [custom] when it is non-empty (after trimming); otherwise picks a
/// default line keyed off `(seed + pickIndex)` so the same draft replays with
/// the same lines and adjacent picks get different ones.
String tauntFor({
  required String? custom,
  required int seed,
  required int pickIndex,
}) {
  final trimmed = custom?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return kDefaultTaunts[(seed + pickIndex) % kDefaultTaunts.length];
}
