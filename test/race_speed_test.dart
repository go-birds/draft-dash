import 'package:draft_race/domain/draft/draft_settings.dart';
import 'package:draft_race/domain/draft/race_speed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('race speed presets have the requested exact durations', () {
    expect(RaceSpeed.values.map((speed) => speed.duration.inSeconds), [
      5,
      10,
      20,
      45,
      60,
    ]);
    expect(RaceSpeed.values.map((speed) => speed.label), [
      'Lightning',
      'Fast',
      'Medium',
      'Slow',
      'Tortoise',
    ]);
  });

  test(
    'selected race speed persists and legacy settings default to medium',
    () {
      for (final speed in RaceSpeed.values) {
        final restored = DraftSettings.fromJson(
          DraftSettings(raceSpeed: speed).toJson(),
        );
        expect(restored.raceSpeed, speed);
      }

      expect(DraftSettings.fromJson(const {}).raceSpeed, RaceSpeed.medium);
      expect(
        DraftSettings.fromJson(const {'raceSpeed': 'unknown'}).raceSpeed,
        RaceSpeed.medium,
      );
    },
  );
}
