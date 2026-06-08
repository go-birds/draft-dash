import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progenitor_core/progenitor_core.dart';

import 'storage/storage_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/state/providers.dart';
import 'ui/theme/app_tokens.dart';

// Inject SENTRY_DSN at build time: --dart-define=SENTRY_DSN=https://...
// Empty string = Sentry no-ops (safe for debug builds).
Future<void> main() => ProgenitorBootstrap.runWithStorage<StorageService>(
  sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
  openStorage: StorageService.open,
  app: (storage) => ProviderScope(
    overrides: [storageProvider.overrideWithValue(storage)],
    child: const MyApp(),
  ),
);

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Keep the observer in place for future animated modes that may need to pause
  // work while the app is backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    switch (s) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // ref.read(gameProvider.notifier).deactivate();
        break;
      case AppLifecycleState.resumed:
        // ref.read(gameProvider.notifier).activate();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return AppThemeScope<DraftTokens>(
      theme: theme,
      child: MaterialApp(
        title: 'Draft Dash',
        debugShowCheckedModeBanner: false,
        theme: _materialTheme(theme),
        home: const HomeScreen(),
      ),
    );
  }

  // Bridges AppTokens → Material ThemeData for built-in widgets (AppBar, dialogs, etc.)
  ThemeData _materialTheme(AppTheme<DraftTokens> t) {
    final tk = t.tokens;
    final base = t.isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: tk.background,
      colorScheme: base.colorScheme.copyWith(
        primary: tk.accent,
        secondary: tk.accent,
        surface: tk.surface,
        error: tk.error,
        onPrimary: tk.background,
        onSurface: tk.textPrimary,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: tk.textPrimary,
        displayColor: tk.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tk.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tk.surfaceElevated,
        contentTextStyle: tk.body,
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tk.accent,
          foregroundColor: tk.background,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: tk.accent),
    );
  }
}
