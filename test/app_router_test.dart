import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/main.dart';
import 'package:draft_race/ui/navigation/app_router.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a top-level URL opens directly and back returns home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app(initialRoute: AppRoutes.history));
    await tester.pumpAndSettle();

    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('No drafts yet'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('FANTASY FOOTBALL'), findsOneWidget);
  });

  testWidgets('unknown URLs fail safely and can return home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app(initialRoute: '/not-a-real-play'));
    await tester.pumpAndSettle();

    expect(find.text('That play is out of bounds.'), findsOneWidget);
    expect(find.text('No page exists at /not-a-real-play.'), findsOneWidget);

    await tester.tap(find.text('BACK TO HOME'));
    await tester.pumpAndSettle();

    expect(find.text('FANTASY FOOTBALL'), findsOneWidget);
  });

  testWidgets('desktop routes expose persistent destination navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app(initialRoute: AppRoutes.history));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('desktop-navigation')), findsOneWidget);
    expect(find.text('Draft setup'), findsOneWidget);
    expect(find.text('League ledger'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-navigation')), findsOneWidget);
  });

  testWidgets('production app honors the platform initial route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        AppRoutes.history;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
    });

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(storage)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('No drafts yet'), findsOneWidget);
  });

  testWidgets('desktop Home to Setup returns Home with Back', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app(initialRoute: AppRoutes.home));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Draft setup'));
    await tester.pumpAndSettle();
    expect(find.text('LEAGUE NAME'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('FANTASY FOOTBALL'), findsOneWidget);
    expect(find.text('CREATE LEAGUE'), findsOneWidget);
  });

  testWidgets('phone routes keep destination navigation compact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app(initialRoute: AppRoutes.settings));
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-navigation')), findsNothing);
  });
}

Future<Widget> _app({required String initialRoute}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  return ProviderScope(
    overrides: [storageProvider.overrideWithValue(storage)],
    child: AppThemeScope<DraftTokens>(
      theme: AppThemes.defaultTheme,
      child: MaterialApp(
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,
        onUnknownRoute: AppRouter.onUnknownRoute,
      ),
    ),
  );
}
