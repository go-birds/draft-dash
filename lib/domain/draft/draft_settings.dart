import 'draft_mode.dart';

/// App-wide preferences (persisted). Pure data.
class DraftSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final DraftMode defaultMode;

  const DraftSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.defaultMode = DraftMode.race,
  });

  DraftSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    DraftMode? defaultMode,
  }) => DraftSettings(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    defaultMode: defaultMode ?? this.defaultMode,
  );

  Map<String, dynamic> toJson() => {
    'sound': soundEnabled,
    'haptics': hapticsEnabled,
    'defaultMode': defaultMode.code,
  };

  static DraftSettings fromJson(Map<String, dynamic> j) => DraftSettings(
    soundEnabled: (j['sound'] as bool?) ?? true,
    hapticsEnabled: (j['haptics'] as bool?) ?? true,
    defaultMode: DraftMode.fromCode((j['defaultMode'] ?? 'race') as String),
  );
}
