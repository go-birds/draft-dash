import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:draft_race/ui/theme/themes.dart';
import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/widgets/football_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'football and basketball race presentations render differently',
    () async {
      final football = await _render(AppThemes.stadium.tokens);
      final basketball = await _render(AppThemes.hardwood.tokens);

      expect(football, isNot(equals(basketball)));
    },
  );
}

Future<Uint8List> _render(DraftTokens tokens) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final painter = FieldRacePainter(
    runners: const [
      RaceRunner(
        color: Color(0xFF3A86FF),
        initials: 'NC',
        progress: .55,
        stride: 2,
      ),
    ],
    leaderProgress: .55,
    introProgress: 1,
    racing: true,
    finished: false,
    tk: tokens,
  );
  painter.paint(canvas, const ui.Size(640, 360));
  final image = await recorder.endRecording().toImage(640, 360);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}
