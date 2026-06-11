import 'package:draft_race/ui/widgets/confetti_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('confetti burst plays through its duration without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConfettiOverlay())),
    );

    expect(
      find.descendant(
        of: find.byType(ConfettiOverlay),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    // Step through the burst and past its ~2.5s duration.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });

  testWidgets('confetti never blocks taps on content underneath', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                ),
              ),
              const Positioned.fill(child: ConfettiOverlay()),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    expect(taps, 1);

    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion renders no confetti CustomPaint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(body: ConfettiOverlay()),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ConfettiOverlay),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
