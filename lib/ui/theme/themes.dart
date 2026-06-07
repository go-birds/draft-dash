import 'package:flutter/widgets.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'app_tokens.dart';

/// Stadium-realism themes. All dark-chrome (the field is green; the UI panels
/// are broadcast scoreboards). [stadium] is the default; [night] is a cooler,
/// deeper "night game under the lights" variant.
abstract class AppThemes {
  static List<AppTheme<DraftTokens>> get all => [stadium, night];

  static AppTheme<DraftTokens> get defaultTheme => stadium;

  static AppTheme<DraftTokens> byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => defaultTheme);

  /// Vivid jersey palette, auto-assigned to managers in roster order.
  static const _jerseys = <Color>[
    Color(0xFF3A86FF), // blue
    Color(0xFFE63946), // red
    Color(0xFFFFB703), // gold
    Color(0xFF06D6A0), // teal
    Color(0xFF9B5DE5), // purple
    Color(0xFFFB5607), // orange
    Color(0xFF34C759), // green
    Color(0xFFFF5DA2), // pink
    Color(0xFF4CC9F0), // cyan
    Color(0xFFB5179E), // magenta
    Color(0xFF8AC926), // lime
    Color(0xFFF15BB5), // rose
  ];

  // ── typography ───────────────────────────────────────────────────────
  static TextStyle _display(Color c) =>
      TextStyle(fontFamily: 'Anton', fontSize: 34, height: 1.0, letterSpacing: .5, color: c);
  static TextStyle _title(Color c) => TextStyle(
      fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: c);
  static TextStyle _body(Color c) => TextStyle(
      fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: c);
  static TextStyle _label(Color c) => TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      color: c);
  static TextStyle _mono(Color c) => TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: c);

  // ─── Stadium (default) ─────────────────────────────────────────────────
  static final stadium = AppTheme<DraftTokens>(
    id: 'stadium',
    name: 'Stadium',
    isDark: true,
    tokens: DraftTokens(
      background: const Color(0xFF0B0F14),
      surface: const Color(0xFF141A22),
      surfaceElevated: const Color(0xFF1B232E),
      accent: const Color(0xFFF5A524),
      error: const Color(0xFFFF3B30),
      success: const Color(0xFF34C759),
      textPrimary: const Color(0xFFF4F7FB),
      textMuted: const Color(0xFF93A1B2),
      gridLine: const Color(0xFF2A3543),
      turf: const Color(0xFF2F8A3B),
      turfDark: const Color(0xFF277A33),
      yardLine: const Color(0xFFF2F6F0),
      endZone: const Color(0xFF13294B),
      endZoneDark: const Color(0xFF0E2140),
      scoreboard: const Color(0xFF0C1118),
      scoreboardLine: const Color(0xFF2A3543),
      gold: const Color(0xFFF5A524),
      led: const Color(0xFF4ADE80),
      whistle: const Color(0xFFFF3B30),
      ice: const Color(0xFF7FB2FF),
      jerseys: _jerseys,
      displayLarge: _display(const Color(0xFFF4F7FB)),
      title: _title(const Color(0xFFF4F7FB)),
      body: _body(const Color(0xFFF4F7FB)),
      label: _label(const Color(0xFF93A1B2)),
      mono: _mono(const Color(0xFFF4F7FB)),
    ),
  );

  // ─── Night Game ────────────────────────────────────────────────────────
  static final night = AppTheme<DraftTokens>(
    id: 'night',
    name: 'Night Game',
    isDark: true,
    tokens: DraftTokens(
      background: const Color(0xFF05070C),
      surface: const Color(0xFF0E1422),
      surfaceElevated: const Color(0xFF161E30),
      accent: const Color(0xFF7FB2FF),
      error: const Color(0xFFFF5A6E),
      success: const Color(0xFF3DDC84),
      textPrimary: const Color(0xFFEAF1FB),
      textMuted: const Color(0xFF8090A8),
      gridLine: const Color(0xFF22304A),
      turf: const Color(0xFF1F6E33),
      turfDark: const Color(0xFF195E2C),
      yardLine: const Color(0xFFDDE8F2),
      endZone: const Color(0xFF0C1E3D),
      endZoneDark: const Color(0xFF08152C),
      scoreboard: const Color(0xFF080D16),
      scoreboardLine: const Color(0xFF22304A),
      gold: const Color(0xFFF5C24B),
      led: const Color(0xFF3DDC84),
      whistle: const Color(0xFFFF5A6E),
      ice: const Color(0xFF9CC4FF),
      jerseys: _jerseys,
      displayLarge: _display(const Color(0xFFEAF1FB)),
      title: _title(const Color(0xFFEAF1FB)),
      body: _body(const Color(0xFFEAF1FB)),
      label: _label(const Color(0xFF8090A8)),
      mono: _mono(const Color(0xFFEAF1FB)),
    ),
  );
}
