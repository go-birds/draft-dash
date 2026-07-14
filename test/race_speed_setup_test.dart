import 'package:draft_race/domain/draft/race_speed.dart';
import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/setup_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('setup selects and persists the exact race speed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.open();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(storage)],
        child: AppThemeScope<DraftTokens>(
          theme: AppThemes.defaultTheme,
          child: const MaterialApp(home: SetupScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final slow = find.byKey(const ValueKey('race-speed-slow'));
    for (var i = 0; i < 8 && slow.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -240));
      await tester.pumpAndSettle();
    }
    expect(slow, findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(slow);
    await tester.pump();

    expect(storage.loadSettings().raceSpeed, RaceSpeed.slow);
    expect(find.text('Slow · 45s'), findsOneWidget);
  });
}
