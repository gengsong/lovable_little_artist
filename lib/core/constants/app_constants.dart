/// 应用常量
class AppConstants {
  AppConstants._();

  // 自动保存
  static const Duration autosaveDelay = Duration(milliseconds: 700);
  static const Duration usageTickInterval = Duration(seconds: 30);

  // 画布
  static const double defaultStrokeWidth = 8.0;
  static const double minStrokeWidth = 2.0;
  static const double maxStrokeWidth = 40.0;
  static const double eraserWidthMultiplier = 2.4;

  // 动画
  static const Duration defaultAnimationDuration = Duration(milliseconds: 200);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // 图片导出
  static const double exportPixelRatio = 2.0;
}
