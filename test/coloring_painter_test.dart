import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/main.dart';
import 'package:lovable_little_artist/studio_localizations.dart';

Future<ByteData> _renderColoringSheet(
  Map<int, Color> fills, {
  ColoringTemplate template = ColoringTemplate.rabbit,
}) async {
  const size = Size(600, 440);
  final recorder = ui.PictureRecorder();
  ColoringPainter(
    template: template,
    fills: fills,
  ).paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(600, 440);
  picture.dispose();
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  return bytes;
}

List<int> _pixel(ByteData bytes, int x, int y) {
  final offset = (y * 600 + x) * 4;
  return List<int>.generate(4, (channel) => bytes.getUint8(offset + channel));
}

void main() {
  test('coloring garden includes fifteen renderable templates', () async {
    expect(ColoringTemplate.values, hasLength(15));
    expect(
      ColoringTemplate.values.map((template) => template.title).toSet(),
      hasLength(15),
    );

    for (final template in ColoringTemplate.values) {
      expect(
        StudioLocalizations.translate(template.title, const Locale('en')),
        isNot(contains(RegExp(r'[\u3400-\u9fff]'))),
      );
      final bytes = await _renderColoringSheet(
        const <int, Color>{},
        template: template,
      );
      expect(_pixel(bytes, 10, 10), const [255, 255, 255, 255]);
    }
  });

  test(
    'fresh coloring sheet has a white paper and white animal regions',
    () async {
      final bytes = await _renderColoringSheet(const <int, Color>{});

      expect(_pixel(bytes, 10, 10), const [255, 255, 255, 255]);
      expect(_pixel(bytes, 300, 120), const [255, 255, 255, 255]);
    },
  );

  test('a region only changes after the child chooses a color', () async {
    final bytes = await _renderColoringSheet(const <int, Color>{
      1: Color(0xFF1976D2),
    });

    expect(_pixel(bytes, 300, 120), const [25, 118, 210, 255]);
    expect(_pixel(bytes, 300, 330), const [255, 255, 255, 255]);
  });
}
