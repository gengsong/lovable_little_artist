import 'package:flutter/material.dart';

/// 应用颜色设计令牌
/// 
/// 定义了整个应用的颜色系统，遵循设计一致性原则。
/// 所有颜色值应该通过这个类访问，而不是硬编码。
class AppColors {
  AppColors._();

  // 基础色板 - 使用简短名称以便向后兼容
  static const Color background = Color(0xFFFFF9EC);
  static const Color ink = Color(0xFF3A1D10);
  static const Color muted = Color(0xFF8A6D5E);
  
  // 调色板
  static const Color peach = Color(0xFFF9DDD1);
  static const Color mint = Color(0xFFD2F2DC);
  static const Color butter = Color(0xFFFFEAB0);
  static const Color rose = Color(0xFFF2DEE8);
  static const Color orange = Color(0xFFFF6B53);
  static const Color brown = Color(0xFF8A6D5E);
  
  // 语义色
  static const Color primary = orange;
  static const Color textPrimary = ink;
  static const Color textSecondary = muted;
  
  // 绘画工具颜色
  static const List<Color> drawingColors = [
    Color(0xFF000000), // 黑色
    Color(0xFF8B4513), // 棕色
    Color(0xFFFF0000), // 红色
    Color(0xFFFF6B53), // 橙色
    Color(0xFFFFD700), // 黄色
    Color(0xFF32CD32), // 绿色
    Color(0xFF00BFFF), // 蓝色
    Color(0xFF9370DB), // 紫色
    Color(0xFFFFB6C1), // 粉色
    Color(0xFFFFFFFF), // 白色
  ];
}
