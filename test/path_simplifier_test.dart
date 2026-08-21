import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/core/utils/path_simplifier.dart';

void main() {
  test('keeps curved points that are outside the tolerance', () {
    final points = [
      Offset.zero,
      const Offset(5, 0),
      const Offset(10, 10),
      const Offset(15, 0),
      const Offset(20, 0),
    ];

    final simplified = PathSimplifier.simplify(points, tolerance: 4);

    expect(simplified, contains(const Offset(10, 10)));
    expect(simplified.first, Offset.zero);
    expect(simplified.last, const Offset(20, 0));
  });

  test('removes small jitter from an almost straight line', () {
    final points = [
      Offset.zero,
      const Offset(4, .2),
      const Offset(8, -.3),
      const Offset(12, .1),
      const Offset(16, 0),
    ];

    final simplified = PathSimplifier.simplify(points, tolerance: 1);

    expect(simplified, [Offset.zero, const Offset(16, 0)]);
  });
}
