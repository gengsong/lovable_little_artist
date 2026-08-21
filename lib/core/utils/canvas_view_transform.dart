import 'dart:ui';

class CanvasViewTransform {
  const CanvasViewTransform({this.scale = 1, this.offset = Offset.zero});

  final double scale;
  final Offset offset;

  Offset toCanvasPosition(Offset localPosition) =>
      (localPosition - offset) / scale;

  CanvasViewTransform reset() => const CanvasViewTransform();

  CanvasViewTransform updateFromGesture({
    required double startDistance,
    required Offset startCenter,
    required double startScale,
    required Offset startOffset,
    required double currentDistance,
    required Offset currentCenter,
    double maxScale = 3.6,
  }) {
    if (startDistance <= 0 || currentDistance <= 0 || startScale <= 0) {
      return this;
    }
    final nextScale = (startScale * currentDistance / startDistance).clamp(
      1.0,
      maxScale,
    );
    final anchor = (startCenter - startOffset) / startScale;
    final nextOffset = nextScale <= 1.01
        ? Offset.zero
        : currentCenter - anchor * nextScale;
    return CanvasViewTransform(scale: nextScale, offset: nextOffset);
  }
}
