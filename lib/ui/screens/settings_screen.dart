import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/app_tokens.dart';
import '../theme/themes.dart';
import '../widgets/confirm_destructive_action.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tk = context.tokens;
    final settings = ref.watch(settingsProvider);
    final sc = ref.read(settingsProvider.notifier);
    final activeTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: tk.background,
      appBar: AppBar(
        backgroundColor: tk.background,
        title: Text('SETTINGS', style: tk.displayLarge.copyWith(fontSize: 24)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _label(tk, 'THEME'),
          for (final t in AppThemes.all)
            InkWell(
              onTap: () => ref.read(themeProvider.notifier).select(t),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _swatch(t.tokens.turf, t.tokens.gold),
                    const SizedBox(width: 14),
                    Expanded(child: Text(t.name, style: tk.body)),
                    Icon(
                      activeTheme.id == t.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: activeTheme.id == t.id ? tk.gold : tk.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          _label(tk, 'GAME DAY'),
          SwitchListTile(
            value: settings.soundEnabled,
            activeThumbColor: tk.gold,
            contentPadding: EdgeInsets.zero,
            title: Text('Sound effects', style: tk.body),
            subtitle: Text(
              'Whistle, crowd, air horn',
              style: tk.body.copyWith(fontSize: 12, color: tk.textMuted),
            ),
            onChanged: sc.setSound,
          ),
          SwitchListTile(
            value: settings.hapticsEnabled,
            activeThumbColor: tk.gold,
            contentPadding: EdgeInsets.zero,
            title: Text('Haptics', style: tk.body),
            subtitle: Text(
              'Vibration on big moments',
              style: tk.body.copyWith(fontSize: 12, color: tk.textMuted),
            ),
            onChanged: sc.setHaptics,
          ),
          const SizedBox(height: 20),
          _label(tk, 'DATA'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: tk.whistle),
            title: Text('Clear saved league', style: tk.body),
            onTap: () async {
              final confirmed = await confirmDestructiveAction(
                context,
                title: 'Clear saved league?',
                message:
                    'This removes saved managers, odds, pins, and league name '
                    'from this device. Draft history stays saved.',
                confirmLabel: 'Clear league',
              );
              if (!confirmed || !context.mounted) return;
              ref.read(draftConfigProvider.notifier).clearLeague();
              ref.read(leagueNameProvider.notifier).set('');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('League cleared')));
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Draft Dash · v1.0.0\nNo internet · No tracking',
              textAlign: TextAlign.center,
              style: tk.body.copyWith(fontSize: 12, color: tk.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(DraftTokens tk, String s) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 6),
    child: Text(s, style: tk.label.copyWith(color: tk.gold)),
  );

  Widget _swatch(Color a, Color b) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: LinearGradient(colors: [a, b]),
    ),
  );
}
