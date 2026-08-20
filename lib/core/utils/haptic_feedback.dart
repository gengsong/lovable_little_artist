import 'package:flutter/services.dart';

/// 触觉反馈工具类
/// 
/// 为交互操作提供触觉反馈，提升用户体验
class AppHaptics {
  AppHaptics._();

  /// 轻触反馈 - 用于按钮点击、选择等
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// 中等反馈 - 用于切换工具、颜色等
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// 重反馈 - 用于删除、清空等重要操作
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// 选择反馈 - 用于滑动选择
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// 成功反馈
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// 错误反馈
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }
}
