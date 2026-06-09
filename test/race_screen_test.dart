import 'dart:ui' as ui;

import 'package:draft_race/storage/storage_service.dart';
import 'package:draft_race/ui/screens/race_screen.dart';
import 'package:draft_race/ui/state/providers.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:draft_race/ui/widgets/football_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progenitor_core/progenitor_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('race screen smoke test builds the broadcast layout', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    final config = container.read(draftConfigProvider.notifier);
    config.addManager('Nick');
    config.addManager('Jordan');
    config.addManager('Taylor');
    config.addManager('Avery');
    container.read(draftControllerProvider.notifier).run();

    await tester.pumpWidget(_raceHarness(container));
    await tester.pump();

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('RUNNING ORDER'), findsOneWidget);
    expect(find.text('LANES SET'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'field race painter renders intro and finish states without throwing',
    () {
      final runners = [
        const RaceRunner(
          color: Color(0xFF3A86FF),
          number: '07',
          progress: 0.02,
          stride: 0,
          leader: false,
        ),
        const RaceRunner(
          color: Color(0xFFE63946),
          number: '23',
          progress: 0.06,
          stride: 0,
          leader: false,
        ),
        const RaceRunner(
          color: Color(0xFFFFB703),
          number: '12',
          progress: 0.10,
          stride: 0,
          leader: false,
        ),
      ];
      final canvasSize = const ui.Size(1280, 720);

      _paint(
        FieldRacePainter(
          runners: runners,
          leaderProgress: 0.0,
          introProgress: 0.65,
          racing: false,
          finished: false,
          tk: AppThemes.defaultTheme.tokens,
        ),
        canvasSize,
      );

      _paint(
        FieldRacePainter(
          runners: runners,
          leaderProgress: 1.0,
          introProgress: 1.0,
          racing: true,
          finished: true,
          tk: AppThemes.defaultTheme.tokens,
        ),
        canvasSize,
      );
    },
  );
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.open();
  return ProviderContainer(
    overrides: [storageProvider.overrideWithValue(storage)],
  );
}

Widget _raceHarness(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: AppThemeScope<DraftTokens>(
    theme: AppThemes.defaultTheme,
    child: const MaterialApp(home: RaceScreen()),
  ),
);

void _paint(FieldRacePainter painter, ui.Size size) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  painter.paint(canvas, size);
  recorder.endRecording();
}
