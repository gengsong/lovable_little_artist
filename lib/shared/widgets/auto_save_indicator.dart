import 'package:flutter/material.dart';
import 'package:lovable_little_artist/core/theme/app_colors.dart';

/// 自动保存指示器
/// 
/// 显示保存状态：保存中、已保存、保存失败
class AutoSaveIndicator extends StatefulWidget {
  const AutoSaveIndicator({
    super.key,
    required this.status,
  });

  final SaveStatus status;

  @override
  State<AutoSaveIndicator> createState() => _AutoSaveIndicatorState();
}

class _AutoSaveIndicatorState extends State<AutoSaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AutoSaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == SaveStatus.idle) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(width: 6),
            Text(
              _getText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _getTextColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    return switch (widget.status) {
      SaveStatus.saving => AppColors.butter,
      SaveStatus.saved => AppColors.mint,
      SaveStatus.error => const Color(0xFFFFE5E5),
      SaveStatus.idle => Colors.transparent,
    };
  }

  Color _getTextColor() {
    return switch (widget.status) {
      SaveStatus.saving => AppColors.brown,
      SaveStatus.saved => const Color(0xFF2D5F3F),
      SaveStatus.error => const Color(0xFFB33A2B),
      SaveStatus.idle => AppColors.textPrimary,
    };
  }

  String _getText() {
    return switch (widget.status) {
      SaveStatus.saving => '保存中...',
      SaveStatus.saved => '已保存',
      SaveStatus.error => '保存失败',
      SaveStatus.idle => '',
    };
  }

  Widget _buildIcon() {
    return switch (widget.status) {
      SaveStatus.saving => SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
          ),
        ),
      SaveStatus.saved => Icon(
          Icons.check_circle_rounded,
          size: 14,
          color: _getTextColor(),
        ),
      SaveStatus.error => Icon(
          Icons.error_rounded,
          size: 14,
          color: _getTextColor(),
        ),
      SaveStatus.idle => const SizedBox.shrink(),
    };
  }
}

enum SaveStatus {
  idle,
  saving,
  saved,
  error,
}
