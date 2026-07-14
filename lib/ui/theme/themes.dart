import 'package:flutter/widgets.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'app_tokens.dart';

/// Two deliberately different sports broadcasts: football turf and a bright
/// basketball hardwood arena.
abstract class AppThemes {
  static List<AppTheme<DraftTokens>> get all => [stadium, hardwood];

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
  static TextStyle _display(Color c) => TextStyle(
    fontFamily: 'Anton',
    fontSize: 34,
    height: 1.0,
    letterSpacing: .5,
    color: c,
  );
  static TextStyle _title(Color c) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: c,
  );
  static TextStyle _body(Color c) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: c,
  );
  static TextStyle _label(Color c) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: c,
  );
  static TextStyle _mono(Color c) => TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: c,
  );

  // ─── Stadium (default) ─────────────────────────────────────────────────
  static final stadium = AppTheme<DraftTokens>(
    id: 'stadium',
    name: 'Football Sunday',
    isDark: true,
    tokens: DraftTokens(
      sport: SportPresentation.football,
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

  // ─── Basketball hardwood ───────────────────────────────────────────────
  static final hardwood = AppTheme<DraftTokens>(
    id: 'hardwood',
    name: 'Basketball Hardwood',
    isDark: false,
    tokens: DraftTokens(
      sport: SportPresentation.basketball,
      background: const Color(0xFFF2E3CA),
      surface: const Color(0xFFFFF8EC),
      surfaceElevated: const Color(0xFFFFFDF8),
      accent: const Color(0xFFC94F18),
      error: const Color(0xFFB42318),
      success: const Color(0xFF287A45),
      textPrimary: const Color(0xFF18233A),
      textMuted: const Color(0xFF657087),
      gridLine: const Color(0xFFD8B98B),
      turf: const Color(0xFFD99B55),
      turfDark: const Color(0xFFE7AE68),
      yardLine: const Color(0xFF7A331D),
      endZone: const Color(0xFF193B70),
      endZoneDark: const Color(0xFF102A52),
      scoreboard: const Color(0xFF17213A),
      scoreboardLine: const Color(0xFF3E5276),
      gold: const Color(0xFFC94F18),
      led: const Color(0xFF47D16C),
      whistle: const Color(0xFFB42318),
      ice: const Color(0xFF255AA5),
      jerseys: _jerseys,
      displayLarge: _display(const Color(0xFF18233A)),
      title: _title(const Color(0xFF18233A)),
      body: _body(const Color(0xFF18233A)),
      label: _label(const Color(0xFF657087)),
      mono: _mono(const Color(0xFF18233A)),
    ),
  );
}
