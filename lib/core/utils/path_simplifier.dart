import 'dart:math' as math;
import 'dart:ui';

/// 道格拉斯-普克算法（Douglas-Peucker）路径简化
///
/// 用于优化绘画笔触路径，减少点的数量，提升渲染性能
class PathSimplifier {
  PathSimplifier._();

  /// 简化路径点列表
  ///
  /// [points] 原始点列表
  /// [tolerance] 容差值，值越大简化程度越高（推荐 1.0-3.0）
  static List<Offset> simplify(List<Offset> points, {double tolerance = 2.0}) {
    if (points.length <= 2) return points;

    // 使用 Douglas-Peucker 算法
    return _douglasPeucker(points, tolerance);
  }

  static List<Offset> _douglasPeucker(List<Offset> points, double tolerance) {
    if (points.length <= 2) return points;

    // 找到距离首尾连线最远的点
    double maxDistance = 0;
    int maxIndex = 0;
    final start = points.first;
    final end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // 如果最大距离大于容差，递归简化
    if (maxDistance > tolerance) {
      final left = _douglasPeucker(points.sublist(0, maxIndex + 1), tolerance);
      final right = _douglasPeucker(points.sublist(maxIndex), tolerance);

      // 合并结果（去掉重复的中间点）
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // 简化为首尾两点
      return [start, end];
    }
  }

  /// 计算点到直线的垂直距离
  static double _perpendicularDistance(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
  ) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    // 如果线段退化为一个点
    if (dx == 0 && dy == 0) {
      return (point - lineStart).distance;
    }

    // 使用点到直线距离公式
    final numerator =
        ((point.dx - lineStart.dx) * dy - (point.dy - lineStart.dy) * dx).abs();
    final denominator = math.sqrt(dx * dx + dy * dy);

    return numerator / denominator;
  }
}
