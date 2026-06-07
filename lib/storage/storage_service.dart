import 'package:shared_preferences/shared_preferences.dart';
import 'package:progenitor_core/progenitor_core.dart';

import '../domain/draft/draft_config.dart';
import '../domain/draft/draft_result.dart';
import '../domain/draft/draft_settings.dart';

/// Typed persistence for Draft Dash. All keys prefixed `draftrace.`.
class StorageService extends ProgenitorStorage {
  static const _kThemeId = 'draftrace.themeId';
  static const _kLeagueName = 'draftrace.leagueName';
  static const _kConfig = 'draftrace.config';
  static const _kSettings = 'draftrace.settings';
  static const _kHistory = 'draftrace.history';

  StorageService._(super.prefs);

  static Future<StorageService> open() async =>
      StorageService._(await SharedPreferences.getInstance());

  // ─── theme ────────────────────────────────────────────────────────────
  String? get themeId => getString(_kThemeId);
  Future<void> setThemeId(String id) => setString(_kThemeId, id);

  // ─── league name ──────────────────────────────────────────────────────
  String get leagueName => getString(_kLeagueName) ?? '';
  Future<void> setLeagueName(String v) => setString(_kLeagueName, v);

  // ─── working draft config (the saved league + setup) ────────────────────
  DraftConfig? loadConfig() {
    final m = getJsonMap(_kConfig);
    if (m == null || m.isEmpty) return null;
    try {
      return DraftConfig.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConfig(DraftConfig cfg) =>
      setJsonMap(_kConfig, cfg.toJson());

  bool get hasSavedLeague {
    final c = loadConfig();
    return c != null && c.participants.isNotEmpty;
  }

  // ─── settings ─────────────────────────────────────────────────────────
  DraftSettings loadSettings() {
    final m = getJsonMap(_kSettings);
    if (m == null || m.isEmpty) return const DraftSettings();
    try {
      return DraftSettings.fromJson(m);
    } catch (_) {
      return const DraftSettings();
    }
  }

  Future<void> saveSettings(DraftSettings s) =>
      setJsonMap(_kSettings, s.toJson());

  // ─── history (past drafts, newest first) ────────────────────────────────
  List<DraftResult> loadHistory() {
    return [
      for (final j in getJsonList(_kHistory))
        if (_tryResult(j) != null) _tryResult(j)!
    ];
  }

  Future<void> saveHistory(List<DraftResult> results) =>
      setJsonList(_kHistory, [for (final r in results) r.toJson()]);

  static DraftResult? _tryResult(Map<String, dynamic> j) {
    try {
      return DraftResult.fromJson(j);
    } catch (_) {
      return null;
    }
  }
}
