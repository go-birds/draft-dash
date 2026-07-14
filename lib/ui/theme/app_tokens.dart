import 'package:flutter/widgets.dart';
import 'package:progenitor_core/progenitor_core.dart';

enum SportPresentation { football, basketball }

/// Stadium-realism design tokens. Extends the Progenitor base with football
/// field + scoreboard colors and a jersey palette for auto-assigning managers.
class DraftTokens extends AppTokens {
  final SportPresentation sport;
  // ─── field ───────────────────────────────────────────────────────────
  final Color turf;
  final Color turfDark;
  final Color yardLine;
  final Color endZone;
  final Color endZoneDark;

  // ─── scoreboard / broadcast chrome ─────────────────────────────────────
  final Color scoreboard;
  final Color scoreboardLine;
  final Color gold; // primary accent (mirrors [accent])
  final Color led; // live indicator green
  final Color whistle; // penalty / danger
  final Color ice; // secondary highlight (cool blue)

  /// Jersey colors auto-assigned to managers in roster order.
  final List<Color> jerseys;

  const DraftTokens({
    this.sport = SportPresentation.football,
    required this.turf,
    required this.turfDark,
    required this.yardLine,
    required this.endZone,
    required this.endZoneDark,
    required this.scoreboard,
    required this.scoreboardLine,
    required this.gold,
    required this.led,
    required this.whistle,
    required this.ice,
    required this.jerseys,
    required super.background,
    required super.surface,
    required super.surfaceElevated,
    required super.accent,
    required super.error,
    required super.success,
    required super.textPrimary,
    required super.textMuted,
    required super.gridLine,
    super.cellGap,
    super.boardPadding,
    super.cellRadius,
    super.cardRadius,
    super.screenPadding,
    required super.displayLarge,
    required super.title,
    required super.body,
    required super.label,
    required super.mono,
  });

  /// A jersey color for the manager at [index] (wraps the palette).
  Color jersey(int index) => jerseys[index % jerseys.length];
}

/// One-line access from any widget: `context.tokens.turf`.
extension AppThemeContext on BuildContext {
  AppTheme<DraftTokens> get appTheme => AppThemeScope.of<DraftTokens>(this);
  DraftTokens get tokens => AppThemeScope.of<DraftTokens>(this).tokens;
}
