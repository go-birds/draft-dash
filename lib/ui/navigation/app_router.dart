import 'package:flutter/material.dart';

import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/league_ledger_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/setup_screen.dart';

/// Stable URLs for the parts of the app that can be opened independently.
abstract final class AppRoutes {
  static const home = '/';
  static const setup = '/setup';
  static const history = '/history';
  static const ledger = '/ledger';
  static const settings = '/settings';

  static const topLevel = <String>[home, setup, history, ledger, settings];
}

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final routeName = _normalizedPath(settings.name);
    final page = switch (routeName) {
      AppRoutes.home => const HomeScreen(),
      AppRoutes.setup => const SetupScreen(),
      AppRoutes.history => const HistoryScreen(),
      AppRoutes.ledger => const LeagueLedgerScreen(),
      AppRoutes.settings => const SettingsScreen(),
      _ => null,
    };

    if (page == null) return onUnknownRoute(settings);

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) =>
          ResponsiveDestinationFrame(routeName: routeName, child: page),
    );
  }

  static Route<void> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _UnknownRouteScreen(requestedRoute: settings.name),
    );
  }

  static String _normalizedPath(String? name) {
    final uri = Uri.tryParse(name ?? AppRoutes.home);
    var path = uri?.path ?? AppRoutes.home;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path.isEmpty ? AppRoutes.home : path;
  }
}

/// Keeps phone navigation compact while making the web/desktop destinations
/// discoverable without repeatedly returning to the home page.
class ResponsiveDestinationFrame extends StatelessWidget {
  const ResponsiveDestinationFrame({
    required this.routeName,
    required this.child,
    super.key,
  });

  static const desktopBreakpoint = 900.0;

  final String routeName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < desktopBreakpoint) return child;

        return Scaffold(
          body: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Row(
              children: [
                NavigationRail(
                  key: const ValueKey('desktop-navigation'),
                  selectedIndex: AppRoutes.topLevel.indexOf(routeName),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('🏈', style: TextStyle(fontSize: 32)),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.sports_score_outlined),
                      selectedIcon: Icon(Icons.sports_score_rounded),
                      label: Text('Draft setup'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history_rounded),
                      label: Text('History'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded),
                      label: Text('League ledger'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                  onDestinationSelected: (index) {
                    final destination = AppRoutes.topLevel[index];
                    if (destination == routeName) return;
                    final navigator = Navigator.of(context);
                    if (destination == AppRoutes.home) {
                      navigator.pushNamedAndRemoveUntil(
                        AppRoutes.home,
                        (_) => false,
                      );
                    } else if (routeName == AppRoutes.home) {
                      navigator.pushNamed(destination);
                    } else {
                      navigator.pushReplacementNamed(destination);
                    }
                  },
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.requestedRoute});

  final String? requestedRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DRAFT DASH')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_football_rounded, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'That play is out of bounds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  requestedRoute == null
                      ? 'The requested page could not be found.'
                      : 'No page exists at $requestedRoute.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('BACK TO HOME'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
