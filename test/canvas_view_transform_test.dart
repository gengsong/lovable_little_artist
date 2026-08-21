import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/core/utils/canvas_view_transform.dart';

void main() {
  test('maps viewport coordinates back to canvas coordinates', () {
    const view = CanvasViewTransform(scale: 2, offset: Offset(20, 30));

    expect(
      view.toCanvasPosition(const Offset(120, 230)),
      const Offset(50, 100),
    );
  });

  test('keeps the gesture anchor stable while pinching', () {
    const view = CanvasViewTransform();

    final next = view.updateFromGesture(
      startDistance: 50,
      startCenter: const Offset(100, 100),
      startScale: 1,
      startOffset: Offset.zero,
      currentDistance: 100,
      currentCenter: const Offset(120, 110),
    );

    expect(next.scale, 2);
    expect(
      next.toCanvasPosition(const Offset(120, 110)),
      const Offset(100, 100),
    );
  });
}
