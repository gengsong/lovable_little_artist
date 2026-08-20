import 'dart:math' as math;

import 'package:flutter/material.dart';

class StudioVisuals {
  const StudioVisuals._();

  static const Color paper = Color(0xFFFFFCF2);
  static const Color warmPaper = Color(0xFFFFF5DC);
  static const Color ink = Color(0xFF3A1D10);
  static const Color clay = Color(0xFFB96F45);
  static const Color coral = Color(0xFFFF6B53);
  static const Color lemon = Color(0xFFFFD85A);
  static const Color sky = Color(0xFF78C7EF);
  static const Color leaf = Color(0xFF72C78D);
  static const Color plum = Color(0xFF8B6FD9);
  static const Color blush = Color(0xFFFFB0A3);
  static const Color shadow = Color(0x246B4B2B);
}

class StoryScaffoldBackdrop extends StatelessWidget {
  const StoryScaffoldBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _StoryBackdropPainter(), child: child);
  }
}

class StoryPaper extends StatelessWidget {
  const StoryPaper({
    super.key,
    required this.child,
    this.color = StudioVisuals.paper,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 28,
    this.shadow = true,
    this.borderColor = const Color(0x22B96F45),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool shadow;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: StudioVisuals.shadow,
                  blurRadius: 0,
                  offset: Offset(0, 7),
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: _StoryPaperPainter(color: color, borderColor: borderColor),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StudioBuddy extends StatelessWidget {
  const StudioBuddy({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _StudioBuddyPainter()),
    );
  }
}

class BrushStrokeBadge extends StatelessWidget {
  const BrushStrokeBadge({
    super.key,
    required this.label,
    this.icon,
    this.fontSize = 24,
    this.color = StudioVisuals.lemon,
  });

  final String label;
  final IconData? icon;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BrushStrokePainter(color),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: StudioVisuals.ink, size: fontSize + 1),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryBackdropPainter extends CustomPainter {
  const _StoryBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFF9EC),
    );

    final washPaint = Paint()..style = PaintingStyle.fill;
    _drawWash(
      canvas,
      Offset(size.width * .14, size.height * .18),
      Size(size.width * .30, size.height * .28),
      StudioVisuals.sky.withValues(alpha: .16),
      0,
      washPaint,
    );
    _drawWash(
      canvas,
      Offset(size.width * .82, size.height * .22),
      Size(size.width * .34, size.height * .24),
      StudioVisuals.blush.withValues(alpha: .18),
      .24,
      washPaint,
    );
    _drawWash(
      canvas,
      Offset(size.width * .72, size.height * .82),
      Size(size.width * .42, size.height * .32),
      StudioVisuals.leaf.withValues(alpha: .14),
      -.18,
      washPaint,
    );

    final fiber = Paint()
      ..color = const Color(0x143A1D10)
      ..strokeWidth = 1;
    for (var i = 0; i < 190; i++) {
      final x = (i * 47.0) % math.max(size.width, 1);
      final y = (i * 83.0) % math.max(size.height, 1);
      final len = 2.0 + (i % 4);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + len, y + (i.isEven ? .5 : -.5)),
        fiber,
      );
    }

    final crayon = Paint()
      ..color = StudioVisuals.coral.withValues(alpha: .18)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(size.width * .06, size.height * .86),
      Offset(size.width * .22, size.height * .83),
      crayon,
    );
    crayon
      ..color = StudioVisuals.plum.withValues(alpha: .15)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(size.width * .74, size.height * .11),
      Offset(size.width * .91, size.height * .14),
      crayon,
    );
  }

  void _drawWash(
    Canvas canvas,
    Offset center,
    Size size,
    Color color,
    double rotation,
    Paint paint,
  ) {
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
    final path = Path();
    for (var i = 0; i < 14; i++) {
      final angle = rotation + (math.pi * 2 * i / 14);
      final wobble = 1 + math.sin(i * 1.7) * .08;
      final point = Offset(
        center.dx + math.cos(angle) * rect.width * .5 * wobble,
        center.dy + math.sin(angle) * rect.height * .5 * wobble,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StoryPaperPainter extends CustomPainter {
  const _StoryPaperPainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);

    final edgePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(Offset.zero & size, edgePaint);

    final speck = Paint()..color = const Color(0x163A1D10);
    for (var i = 0; i < 62; i++) {
      final x = (i * 29.0) % math.max(size.width, 1);
      final y = (i * 43.0) % math.max(size.height, 1);
      canvas.drawCircle(Offset(x, y), i.isEven ? .75 : .45, speck);
    }

    final fiber = Paint()
      ..color = const Color(0x11B96F45)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final y = (i * 31.0) % math.max(size.height, 1);
      canvas.drawLine(Offset(0, y), Offset(10 + (i % 5) * 4, y + 1), fiber);
      canvas.drawLine(
        Offset(size.width, y + 13),
        Offset(size.width - 12 - (i % 4) * 3, y + 14),
        fiber,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StoryPaperPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}

class _BrushStrokePainter extends CustomPainter {
  const _BrushStrokePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(6, size.height * .35)
      ..quadraticBezierTo(size.width * .22, 0, size.width * .46, 7)
      ..quadraticBezierTo(size.width * .72, 14, size.width - 8, 5)
      ..quadraticBezierTo(
        size.width,
        size.height * .5,
        size.width - 6,
        size.height - 8,
      )
      ..quadraticBezierTo(
        size.width * .68,
        size.height + 2,
        size.width * .38,
        size.height - 5,
      )
      ..quadraticBezierTo(
        size.width * .14,
        size.height - 12,
        5,
        size.height - 2,
      )
      ..quadraticBezierTo(0, size.height * .62, 6, size.height * .35)
      ..close();
    canvas.drawPath(path, paint);

    final grain = Paint()
      ..color = Colors.white.withValues(alpha: .30)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (.35 + i * .12);
      canvas.drawLine(
        Offset(14 + i * 8, y),
        Offset(size.width - 18 - i * 5, y + 2),
        grain,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrushStrokePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _StudioBuddyPainter extends CustomPainter {
  const _StudioBuddyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final shadow = Paint()..color = StudioVisuals.shadow;
    canvas.drawOval(const Rect.fromLTWH(20, 80, 60, 10), shadow);

    final body = Path()
      ..moveTo(50, 10)
      ..cubicTo(67, 16, 82, 32, 78, 54)
      ..cubicTo(74, 76, 60, 86, 41, 82)
      ..cubicTo(23, 78, 15, 61, 22, 42)
      ..cubicTo(27, 27, 35, 15, 50, 10)
      ..close();
    canvas.drawPath(body, Paint()..color = StudioVisuals.lemon);

    final cutEdge = Paint()
      ..color = StudioVisuals.clay.withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(body, cutEdge);

    final cap = Path()
      ..moveTo(31, 25)
      ..cubicTo(42, 5, 68, 8, 74, 26)
      ..cubicTo(61, 21, 46, 20, 31, 25)
      ..close();
    canvas.drawPath(cap, Paint()..color = StudioVisuals.sky);
    canvas.drawPath(
      cap,
      cutEdge..color = StudioVisuals.ink.withValues(alpha: .18),
    );

    final brush = Paint()
      ..color = StudioVisuals.ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(70, 19), const Offset(86, 8), brush);
    canvas.drawCircle(
      const Offset(88, 7),
      4,
      Paint()..color = StudioVisuals.coral,
    );

    final eye = Paint()..color = StudioVisuals.ink;
    canvas.drawCircle(const Offset(39, 49), 3.2, eye);
    canvas.drawCircle(const Offset(61, 49), 3.2, eye);
    final smile = Paint()
      ..color = StudioVisuals.ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    canvas.drawArc(
      const Rect.fromLTWH(41, 50, 18, 15),
      .25,
      math.pi - .5,
      false,
      smile,
    );

    final cheek = Paint()..color = StudioVisuals.blush.withValues(alpha: .78);
    canvas.drawCircle(const Offset(31, 58), 4.5, cheek);
    canvas.drawCircle(const Offset(69, 58), 4.5, cheek);

    final apron = Path()
      ..moveTo(33, 65)
      ..lineTo(66, 63)
      ..lineTo(61, 80)
      ..quadraticBezierTo(49, 85, 38, 79)
      ..close();
    canvas.drawPath(apron, Paint()..color = StudioVisuals.paper);

    final dots = Paint()..color = StudioVisuals.coral;
    canvas.drawCircle(const Offset(44, 71), 2.5, dots);
    dots.color = StudioVisuals.leaf;
    canvas.drawCircle(const Offset(56, 70), 2.2, dots);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
