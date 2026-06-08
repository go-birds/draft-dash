import 'package:flutter/painting.dart';

/// Small color helpers shared by jersey chips, sprites, and the field.
Color lighten(Color c, [double amt = .14]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + amt).clamp(0.0, 1.0)).toColor();
}

Color darken(Color c, [double amt = .14]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amt).clamp(0.0, 1.0)).toColor();
}

/// Readable text color (black/white) for a filled [c] background.
Color onColor(Color c) => c.computeLuminance() > 0.55
    ? const Color(0xFF1A1206)
    : const Color(0xFFFFFFFF);

/// Top-lit gradient stops for a jersey/ball fill.
List<Color> jerseyGradient(Color c) => [lighten(c, .12), c, darken(c, .16)];
