import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/main.dart';

Future<ui.Image> _render(CustomPainter painter) async {
  const size = Size(300, 300);
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(300, 300);
  picture.dispose();
  return image;
}

Future<ByteData> _rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

void main() {
  test('lesson canvas guide is dashed while preview stays solid', () async {
    final dashed = await _render(
      LessonGuidePainter(
        art: LessonArt.cat,
        visibleSteps: 1,
        accent: Colors.orange,
      ),
    );
    final solid = await _render(
      LessonGuidePainter(
        art: LessonArt.cat,
        visibleSteps: 1,
        accent: Colors.orange,
        preview: true,
      ),
    );
    final dashedBytes = await _rgba(dashed);
    final solidBytes = await _rgba(solid);
    int paintedSamples(ByteData bytes) {
      var count = 0;
      for (var degree = 0; degree < 360; degree++) {
        final angle = degree * 3.141592653589793 / 180;
        final x = (150 + 72 * math.cos(angle)).round();
        final y = (161 + 72 * math.sin(angle)).round();
        final offset = (y * 300 + x) * 4 + 3;
        if (bytes.getUint8(offset) > 20) count++;
      }
      return count;
    }

    expect(
      paintedSamples(dashedBytes),
      lessThan(paintedSamples(solidBytes) * .85),
    );
    dashed.dispose();
    solid.dispose();
  });

  test('child drawing stroke remains a continuous solid line', () async {
    final image = await _render(
      NativeCanvasPainter(
        strokes: [
          DrawingStroke(
            tool: DrawingTool.crayon,
            color: const Color(0xFFFF6B53),
            baseWidth: 10,
            points: const [
              DrawingPoint(Offset(20, 150), 1),
              DrawingPoint(Offset(280, 150), 1),
            ],
          ),
        ],
      ),
    );
    final bytes = await _rgba(image);
    for (var x = 25; x <= 275; x += 10) {
      final offset = (150 * 300 + x) * 4;
      expect(bytes.getUint8(offset), greaterThan(220));
      expect(bytes.getUint8(offset + 1), lessThan(150));
      expect(bytes.getUint8(offset + 2), lessThan(130));
    }
    image.dispose();
  });
}
