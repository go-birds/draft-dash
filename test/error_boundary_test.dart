import 'package:flutter_test/flutter_test.dart';

import 'package:draft_race/ui/widgets/error_boundary.dart';

void main() {
  testWidgets('ErrorBoundaryFallback renders headline and subtext', (
    tester,
  ) async {
    // Pumped bare on purpose: the fallback must render without MaterialApp,
    // an inherited theme, or Directionality (the tree is broken when it shows).
    await tester.pumpWidget(const ErrorBoundaryFallback());

    expect(find.text('Fumble! Something went wrong'), findsOneWidget);
    expect(
      find.text('Restart the app to get back on the field.'),
      findsOneWidget,
    );
  });
}
