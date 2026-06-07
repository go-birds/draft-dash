import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/state/providers.dart';
import 'sound_service.dart';

/// Combined haptics + SFX, gated by user settings. Named [AppFeedback] to avoid
/// clashing with Flutter's material `Feedback`.
class AppFeedback {
  final bool sound;
  final bool haptics;
  const AppFeedback(this.sound, this.haptics);

  factory AppFeedback.of(WidgetRef ref) {
    final s = ref.read(settingsProvider);
    return AppFeedback(s.soundEnabled, s.hapticsEnabled);
  }

  void _h(void Function() f) {
    if (haptics) f();
  }

  void _s(String name, {double volume = 1.0}) {
    if (sound) SoundService.instance.play(name, volume: volume);
  }

  void tap() => _h(HapticFeedback.selectionClick);
  void countdownTick() {
    _h(HapticFeedback.selectionClick);
    _s('beep');
  }

  void whistle() {
    _h(HapticFeedback.mediumImpact);
    _s('whistle');
  }

  void cardFlip() {
    _h(HapticFeedback.selectionClick);
    _s('card_flip', volume: 0.9);
  }

  void ballDraw() {
    _h(HapticFeedback.lightImpact);
    _s('ball');
  }

  void award() {
    _h(HapticFeedback.mediumImpact);
    _s('whistle');
  }

  void win() {
    _h(HapticFeedback.heavyImpact);
    _s('airhorn');
  }
}
