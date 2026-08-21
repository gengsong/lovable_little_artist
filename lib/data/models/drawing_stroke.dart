import 'dart:math' as math;
import 'dart:ui';

import 'package:lovable_little_artist/core/utils/path_simplifier.dart';

enum DrawingTool {
  crayon,
  watercolor,
  marker,
  pencil,
  glow,
  eraser,
  spray,
  pattern,
  stamp,
  sticker,
  fill,
}

enum DrawingLayer {
  background('background'),
  artwork('artwork'),
  stickers('stickers');

  const DrawingLayer(this.id);

  final String id;

  static DrawingLayer byId(String? id) => DrawingLayer.values.firstWhere(
    (layer) => layer.id == id,
    orElse: () => DrawingLayer.artwork,
  );
}

extension DrawingToolBehavior on DrawingTool {
  bool get isDiscrete =>
      this == DrawingTool.stamp ||
      this == DrawingTool.sticker ||
      this == DrawingTool.fill;

  DrawingLayer get defaultLayer => switch (this) {
    DrawingTool.fill => DrawingLayer.background,
    DrawingTool.stamp || DrawingTool.sticker => DrawingLayer.stickers,
    _ => DrawingLayer.artwork,
  };
}

class DrawingPoint {
  const DrawingPoint(this.offset, this.pressure);

  final Offset offset;
  final double pressure;
}

class DrawingStroke {
  DrawingStroke({
    required this.tool,
    required this.color,
    required this.baseWidth,
    required this.points,
    String? layerId,
  }) : layerId = layerId ?? tool.defaultLayer.id;

  final DrawingTool tool;
  final Color color;
  double baseWidth;
  final List<DrawingPoint> points;
  String layerId;

  DrawingStroke copy() => DrawingStroke(
    tool: tool,
    color: color,
    baseWidth: baseWidth,
    layerId: layerId,
    points: [
      for (final point in points) DrawingPoint(point.offset, point.pressure),
    ],
  );
}

void simplifyStrokeInPlace(DrawingStroke? stroke) {
  if (stroke == null || stroke.tool.isDiscrete || stroke.points.length <= 3) {
    return;
  }
  final simplifiedOffsets = PathSimplifier.simplify([
    for (final point in stroke.points) point.offset,
  ], tolerance: math.max(1.1, stroke.baseWidth * .16));
  if (simplifiedOffsets.length >= stroke.points.length) return;

  var searchFrom = 0;
  final simplifiedPoints = <DrawingPoint>[];
  for (final offset in simplifiedOffsets) {
    var matchIndex = searchFrom;
    while (matchIndex < stroke.points.length &&
        stroke.points[matchIndex].offset != offset) {
      matchIndex++;
    }
    if (matchIndex >= stroke.points.length) continue;
    simplifiedPoints.add(stroke.points[matchIndex]);
    searchFrom = matchIndex + 1;
  }
  if (simplifiedPoints.length < 2) return;
  stroke.points
    ..clear()
    ..addAll(simplifiedPoints);
}

Map<String, Object?> draftFromStrokes(
  List<DrawingStroke> strokes, {
  int? stepIndex,
  Size? canvasSize,
}) => {
  'version': 1,
  'stepIndex': ?stepIndex,
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
  if (canvasSize != null) 'canvasWidth': canvasSize.width,
  if (canvasSize != null) 'canvasHeight': canvasSize.height,
  'strokes': [
    for (final stroke in strokes)
      {
        'tool': stroke.tool.name,
        'layer': stroke.layerId,
        'color': stroke.color.toARGB32(),
        'width': stroke.baseWidth,
        'points': [
          for (final point in stroke.points)
            [point.offset.dx, point.offset.dy, point.pressure],
        ],
      },
  ],
};

List<DrawingStroke> strokesFromDraft(Map<String, Object?>? draft) {
  if (draft == null) return [];
  try {
    return [
      for (final item in draft['strokes'] as List<dynamic>)
        DrawingStroke(
          tool: DrawingTool.values.byName(
            (item as Map<String, dynamic>)['tool'] as String,
          ),
          color: Color((item['color'] as num).toInt()),
          baseWidth: (item['width'] as num).toDouble(),
          layerId: item['layer'] as String?,
          points: [
            for (final point in item['points'] as List<dynamic>)
              DrawingPoint(
                Offset(
                  (point[0] as num).toDouble(),
                  (point[1] as num).toDouble(),
                ),
                (point[2] as num).toDouble(),
              ),
          ],
        ),
    ];
  } catch (_) {
    return [];
  }
}
