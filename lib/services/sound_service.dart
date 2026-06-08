import 'package:audioplayers/audioplayers.dart';

/// Plays short bundled SFX. Files live in `assets/audio/<name>.wav`.
/// Missing files fail silently so the app works before assets are added.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final _pool = <AudioPlayer>[];
  int _next = 0;
  static const _poolSize = 4;

  void _ensure() {
    if (_pool.isNotEmpty) return;
    for (var i = 0; i < _poolSize; i++) {
      _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
    }
  }

  Future<void> play(String name, {double volume = 1.0}) async {
    try {
      _ensure();
      final p = _pool[_next++ % _pool.length];
      await p.stop();
      await p.setVolume(volume);
      await p.play(AssetSource('audio/$name.wav'));
    } catch (_) {
      // No asset yet (or playback unavailable) — ignore.
    }
  }
}
