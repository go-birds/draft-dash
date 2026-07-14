import 'draft_mode.dart';
import 'race_speed.dart';

/// App-wide preferences (persisted). Pure data.
class DraftSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final DraftMode defaultMode;
  final RaceSpeed raceSpeed;

  const DraftSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.defaultMode = DraftMode.race,
    this.raceSpeed = RaceSpeed.medium,
  });

  DraftSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    DraftMode? defaultMode,
    RaceSpeed? raceSpeed,
  }) => DraftSettings(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    defaultMode: defaultMode ?? this.defaultMode,
    raceSpeed: raceSpeed ?? this.raceSpeed,
  );

  Map<String, dynamic> toJson() => {
    'sound': soundEnabled,
    'haptics': hapticsEnabled,
    'defaultMode': defaultMode.code,
    'raceSpeed': raceSpeed.code,
  };

  static DraftSettings fromJson(Map<String, dynamic> j) => DraftSettings(
    soundEnabled: (j['sound'] as bool?) ?? true,
    hapticsEnabled: (j['haptics'] as bool?) ?? true,
    defaultMode: DraftMode.fromCode((j['defaultMode'] ?? 'race') as String),
    raceSpeed: RaceSpeed.fromCode(j['raceSpeed'] as String?),
  );
}
