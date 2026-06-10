import 'package:flutter/widgets.dart';

/// Branded fallback rendered in place of Flutter's default error widget in
/// release builds (wired via `ErrorWidget.builder` in main.dart).
///
/// Deliberately self-contained: it renders when the widget tree is broken, so
/// it must not depend on an inherited theme, Material, or Directionality
/// being alive. Colors are copied from the Stadium theme tokens in
/// lib/ui/theme/themes.dart.
class ErrorBoundaryFallback extends StatelessWidget {
  const ErrorBoundaryFallback({super.key});

  // Stadium theme tokens (hardcoded on purpose — see class doc).
  static const Color _background = Color(0xFF0B0F14);
  static const Color _surface = Color(0xFF141A22);
  static const Color _gridLine = Color(0xFF2A3543);
  static const Color _textPrimary = Color(0xFFF4F7FB);
  static const Color _textMuted = Color(0xFF93A1B2);

  static const String headline = 'Fumble! Something went wrong';
  static const String subtext = 'Restart the app to get back on the field.';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _background,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gridLine),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏈', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtext,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
