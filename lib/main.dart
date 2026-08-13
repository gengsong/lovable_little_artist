import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(const LittleArtistVerseApp());

const _bg = Color(0xFFFFF9EC);
const _ink = Color(0xFF3A1D10);
const _muted = Color(0xFF8A6D5E);
const _peach = Color(0xFFF9DDD1);
const _mint = Color(0xFFD2F2DC);
const _butter = Color(0xFFFFEAB0);
const _rose = Color(0xFFF2DEE8);
const _orange = Color(0xFFFF6B53);
const _brown = Color(0xFF8A6D5E);

class LittleArtistVerseApp extends StatelessWidget {
  const LittleArtistVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '小小画室 Little Art Studio',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(seedColor: _orange, brightness: Brightness.light),
        textTheme: ThemeData.light().textTheme.apply(bodyColor: _ink, displayColor: _ink),
      ),
      home: const StudioHome(),
    );
  }
}

enum StudioTab { home, draw, lessons, gallery, animation, parent }

class StudioHome extends StatefulWidget {
  const StudioHome({super.key});

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  StudioTab tab = StudioTab.home;
  final sketches = const [
    RecentSketch('开心的太阳', SketchKind.sun),
    RecentSketch('我的小房子', SketchKind.house),
    RecentSketch('打瞌睡的小猫', SketchKind.cat),
    RecentSketch('月亮火箭', SketchKind.rocket),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 820;
        final content = switch (tab) {
          StudioTab.home => Dashboard(
              sketches: sketches,
              onOpen: (next) => setState(() => tab = next),
            ),
          StudioTab.draw => DrawPage(onBack: () => setState(() => tab = StudioTab.home)),
          StudioTab.lessons => LessonsPage(onBack: () => setState(() => tab = StudioTab.home)),
          StudioTab.gallery => GalleryPage(sketches: sketches, onBack: () => setState(() => tab = StudioTab.home)),
          StudioTab.animation => AnimationPage(onBack: () => setState(() => tab = StudioTab.home)),
          StudioTab.parent => ParentPage(onBack: () => setState(() => tab = StudioTab.home)),
        };

        return Scaffold(
          backgroundColor: _bg,
          bottomNavigationBar: isTablet
              ? null
              : StudioBottomNav(
                  selected: tab,
                  onSelect: (next) => setState(() => tab = next),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (isTablet)
                  StudioRail(
                    selected: tab,
                    onSelect: (next) => setState(() => tab = next),
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 1080 : 520),
                      child: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StudioRail extends StatelessWidget {
  const StudioRail({super.key, required this.selected, required this.onSelect});

  final StudioTab selected;
  final ValueChanged<StudioTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      (StudioTab.home, Icons.home_rounded, '首页'),
      (StudioTab.draw, Icons.palette_rounded, '画画'),
      (StudioTab.lessons, Icons.menu_book_rounded, '课程'),
      (StudioTab.gallery, Icons.photo_library_rounded, '作品集'),
      (StudioTab.animation, Icons.auto_awesome_rounded, '动画'),
    ];
    return Container(
      width: 96,
      color: Colors.white.withValues(alpha: .56),
      child: Column(
        children: [
          const SizedBox(height: 26),
          const Icon(Icons.palette_rounded, color: _orange, size: 30),
          const SizedBox(height: 28),
          for (final item in items)
            NavPill(
              icon: item.$2,
              label: item.$3,
              selected: selected == item.$1,
              onTap: () => onSelect(item.$1),
            ),
          const Spacer(),
          NavPill(icon: Icons.translate_rounded, label: 'EN', selected: false, onTap: () {}),
          NavPill(icon: Icons.verified_user_outlined, label: '家长', selected: selected == StudioTab.parent, onTap: () => onSelect(StudioTab.parent)),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class NavPill extends StatelessWidget {
  const NavPill({super.key, required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFE3DC) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? _orange : _brown, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: selected ? _orange : _brown, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class StudioBottomNav extends StatelessWidget {
  const StudioBottomNav({super.key, required this.selected, required this.onSelect});

  final StudioTab selected;
  final ValueChanged<StudioTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      (StudioTab.home, Icons.home_rounded, '首页'),
      (StudioTab.draw, Icons.palette_rounded, '画画'),
      (StudioTab.lessons, Icons.menu_book_rounded, '课程'),
      (StudioTab.gallery, Icons.photo_library_rounded, '作品集'),
      (StudioTab.animation, Icons.auto_awesome_rounded, '动画'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEADBC7))),
      ),
      child: NavigationBar(
        height: 76,
        backgroundColor: Colors.white,
        selectedIndex: math.max(0, items.indexWhere((item) => item.$1 == selected)),
        onDestinationSelected: (index) => onSelect(items[index].$1),
        indicatorColor: const Color(0xFFFFE4DD),
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.$2, color: _brown),
              selectedIcon: Icon(item.$2, color: _orange),
              label: item.$3,
            ),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.sketches, required this.onOpen});

  final List<RecentSketch> sketches;
  final ValueChanged<StudioTab> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 820;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(isTablet ? 26 : 20, isTablet ? 20 : 24, isTablet ? 28 : 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeroGreeting(onParent: () => onOpen(StudioTab.parent)),
              SizedBox(height: isTablet ? 30 : 42),
              Text('今天想做什么？', style: TextStyle(fontSize: isTablet ? 22 : 34, fontWeight: FontWeight.w900, color: _ink)),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: isTablet ? 18 : 20,
                crossAxisSpacing: isTablet ? 18 : 20,
                childAspectRatio: isTablet ? 2.35 : .98,
                children: [
                  ActionTile(title: '自由画画', subtitle: '随心创作', icon: Icons.palette_rounded, iconColor: _orange, color: _peach, onTap: () => onOpen(StudioTab.draw)),
                  ActionTile(title: '跟着学画', subtitle: '一步一步学', icon: Icons.menu_book_rounded, iconColor: const Color(0xFF07523E), color: _mint, onTap: () => onOpen(StudioTab.lessons)),
                  ActionTile(title: '我的作品集', subtitle: '你的画作', icon: Icons.photo_library_rounded, iconColor: const Color(0xFF6E3D00), color: _butter, onTap: () => onOpen(StudioTab.gallery)),
                  ActionTile(title: '动画故事', subtitle: '让画动起来', icon: Icons.auto_awesome_rounded, iconColor: const Color(0xFF5B285F), color: _rose, onTap: () => onOpen(StudioTab.animation)),
                ],
              ),
              SizedBox(height: isTablet ? 32 : 34),
              Row(
                children: [
                  Text('最近画的', style: TextStyle(fontSize: isTablet ? 21 : 32, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => onOpen(StudioTab.gallery),
                    child: const Text('查看全部', style: TextStyle(color: _orange, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: isTablet ? 180 : 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sketches.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => RecentCard(sketch: sketches[index], compact: isTablet),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HeroGreeting extends StatelessWidget {
  const HeroGreeting({super.key, required this.onParent});

  final VoidCallback onParent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(44),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .10), blurRadius: 28, offset: const Offset(0, 14))],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(radius: 44, backgroundColor: Color(0xFFFFDD78), child: Text('🦊', style: TextStyle(fontSize: 38))),
              Positioned(right: -4, top: -8, child: _Dot(color: const Color(0xFFFFDD78), size: 16)),
              Positioned(left: 10, bottom: -8, child: _Dot(color: const Color(0xFFE6B4EF), size: 14)),
            ],
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你好，', style: TextStyle(color: _muted, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('米娅!', style: TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w900, color: _ink)),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF2E9DE), foregroundColor: _ink, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
            onPressed: () {},
            icon: const Icon(Icons.translate_rounded),
            label: const Text('EN', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF2E9DE), foregroundColor: _brown),
            onPressed: onParent,
            icon: const Icon(Icons.verified_user_outlined),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.title, required this.subtitle, required this.icon, required this.iconColor, required this.color, required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(36),
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [BoxShadow(color: const Color(0xFF6E5A45).withValues(alpha: .18), blurRadius: 0, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(radius: 31, backgroundColor: Colors.white, child: Icon(icon, color: iconColor, size: 32)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _ink)),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(fontSize: 17, color: _muted, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SketchKind { sun, house, cat, rocket }

class RecentSketch {
  const RecentSketch(this.title, this.kind);
  final String title;
  final SketchKind kind;
}

class RecentCard extends StatelessWidget {
  const RecentCard({super.key, required this.sketch, this.compact = false});

  final RecentSketch sketch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 160 : 258,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: CustomPaint(painter: SketchPainter(sketch.kind), child: const SizedBox.expand())),
          const SizedBox(height: 10),
          Text(sketch.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 14 : 23, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class SketchPainter extends CustomPainter {
  SketchPainter(this.kind);
  final SketchKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    switch (kind) {
      case SketchKind.sun:
        final p = Paint()..color = const Color(0xFFFFB45E);
        canvas.drawCircle(c, size.shortestSide * .24, p);
        final ray = Paint()
          ..color = const Color(0xFFFF805F)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * size.shortestSide * .36, c + Offset(math.cos(a), math.sin(a)) * size.shortestSide * .48, ray);
        }
      case SketchKind.house:
        canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, 18), width: size.width * .42, height: size.height * .36), Paint()..color = const Color(0xFF7ED3CE));
        final roof = Path()
          ..moveTo(c.dx - size.width * .28, c.dy)
          ..lineTo(c.dx, c.dy - size.height * .28)
          ..lineTo(c.dx + size.width * .28, c.dy)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFF56B5E8));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, size.height * .2), width: 34, height: 58), const Radius.circular(8)), Paint()..color = Colors.white);
      case SketchKind.cat:
        final p = Paint()..color = const Color(0xFFFF8D86);
        canvas.drawCircle(c, size.shortestSide * .25, p);
        final leftEar = Path()
          ..moveTo(c.dx - 35, c.dy - 20)
          ..lineTo(c.dx - 55, c.dy - 62)
          ..lineTo(c.dx - 8, c.dy - 42)
          ..close();
        final rightEar = Path()
          ..moveTo(c.dx + 35, c.dy - 20)
          ..lineTo(c.dx + 55, c.dy - 62)
          ..lineTo(c.dx + 8, c.dy - 42)
          ..close();
        canvas.drawPath(leftEar, p);
        canvas.drawPath(rightEar, p);
        canvas.drawCircle(c + const Offset(-20, -4), 5, Paint()..color = _ink);
        canvas.drawCircle(c + const Offset(20, -4), 5, Paint()..color = _ink);
        canvas.drawArc(Rect.fromCenter(center: c + const Offset(0, 16), width: 42, height: 24), 0, math.pi, false, Paint()..color = _ink..strokeWidth = 4..style = PaintingStyle.stroke);
      case SketchKind.rocket:
        final body = Path()
          ..moveTo(c.dx, c.dy - size.height * .34)
          ..quadraticBezierTo(c.dx + 36, c.dy - 4, c.dx + 18, c.dy + 54)
          ..lineTo(c.dx - 18, c.dy + 54)
          ..quadraticBezierTo(c.dx - 36, c.dy - 4, c.dx, c.dy - size.height * .34)
          ..close();
        canvas.drawPath(body, Paint()..color = const Color(0xFF82A8FF));
        canvas.drawCircle(c + const Offset(0, -22), 13, Paint()..color = Colors.white);
        canvas.drawPath(Path()..moveTo(c.dx - 18, c.dy + 42)..lineTo(c.dx - 52, c.dy + 72)..lineTo(c.dx - 8, c.dy + 60)..close(), Paint()..color = const Color(0xFF8D8AF9));
        canvas.drawPath(Path()..moveTo(c.dx + 18, c.dy + 42)..lineTo(c.dx + 52, c.dy + 72)..lineTo(c.dx + 8, c.dy + 60)..close(), Paint()..color = const Color(0xFF8D8AF9));
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) => oldDelegate.kind != kind;
}

class DrawPage extends StatefulWidget {
  const DrawPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final _canvasKey = GlobalKey();
  final _strokes = <DrawingStroke>[];
  final _redoStack = <DrawingStroke>[];
  DrawingStroke? _activeStroke;
  DrawingTool _tool = DrawingTool.crayon;
  Color _color = _orange;
  double _width = 10;

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  void _startStroke(PointerDownEvent event) {
    final stroke = DrawingStroke(
      tool: _tool,
      color: _tool == DrawingTool.eraser ? Colors.white : _color,
      baseWidth: _tool == DrawingTool.eraser ? _width * 2.4 : _width,
      points: [DrawingPoint(event.localPosition, _pressure(event))],
    );
    setState(() {
      _redoStack.clear();
      _activeStroke = stroke;
      _strokes.add(stroke);
    });
  }

  void _extendStroke(PointerMoveEvent event) {
    setState(() {
      _activeStroke?.points.add(DrawingPoint(event.localPosition, _pressure(event)));
    });
  }

  void _endStroke(PointerEvent event) {
    _activeStroke = null;
  }

  double _pressure(PointerEvent event) {
    if (event.kind != ui.PointerDeviceKind.stylus && event.kind != ui.PointerDeviceKind.invertedStylus) {
      return 1;
    }
    if (event.pressureMax <= event.pressureMin) {
      return 1;
    }
    return ((event.pressure - event.pressureMin) / (event.pressureMax - event.pressureMin)).clamp(.35, 1.4);
  }

  void _undo() {
    if (!_canUndo) return;
    setState(() => _redoStack.add(_strokes.removeLast()));
  }

  void _redo() {
    if (!_canRedo) return;
    setState(() => _strokes.add(_redoStack.removeLast()));
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack
        ..clear()
        ..addAll(_strokes);
      _strokes.clear();
    });
  }

  Future<void> _savePreview() async {
    final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    final sizeKb = ((data?.lengthInBytes ?? 0) / 1024).round();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sizeKb > 0 ? '已生成作品预览 PNG，约 $sizeKb KB' : '已保存作品预览'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = [_orange, const Color(0xFFFF9D00), const Color(0xFF20B26B), const Color(0xFF45A7E8), const Color(0xFF8C63E8), const Color(0xFF3A1D10)];
    return AppPage(
      title: '自由画画',
      onBack: widget.onBack,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 780;
          final tools = DrawingToolPanel(
            tool: _tool,
            color: _color,
            width: _width,
            colors: colors,
            canUndo: _canUndo,
            canRedo: _canRedo,
            onTool: (tool) => setState(() => _tool = tool),
            onColor: (color) => setState(() {
              _color = color;
              if (_tool == DrawingTool.eraser) _tool = DrawingTool.crayon;
            }),
            onWidth: (width) => setState(() => _width = width),
            onUndo: _undo,
            onRedo: _redo,
            onClear: _clear,
            onSave: _savePreview,
          );

          final canvas = RepaintBoundary(
            key: _canvasKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _startStroke,
                onPointerMove: _extendStroke,
                onPointerUp: _endStroke,
                onPointerCancel: _endStroke,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CustomPaint(
                    painter: NativeCanvasPainter(strokes: _strokes),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          );

          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            children: [
              Expanded(child: canvas),
              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 14),
              SizedBox(
                width: isWide ? 178 : double.infinity,
                child: tools,
              ),
            ],
          );
        },
      ),
    );
  }
}

enum DrawingTool { crayon, marker, glow, eraser }

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
  });

  final DrawingTool tool;
  final Color color;
  final double baseWidth;
  final List<DrawingPoint> points;
}

class DrawingToolPanel extends StatelessWidget {
  const DrawingToolPanel({
    super.key,
    required this.tool,
    required this.color,
    required this.width,
    required this.colors,
    required this.canUndo,
    required this.canRedo,
    required this.onTool,
    required this.onColor,
    required this.onWidth,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onSave,
  });

  final DrawingTool tool;
  final Color color;
  final double width;
  final List<Color> colors;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<DrawingTool> onTool;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onWidth;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 420;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Flex(
            direction: horizontal ? Axis.horizontal : Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ToolChip(icon: Icons.edit_rounded, selected: tool == DrawingTool.crayon, onTap: () => onTool(DrawingTool.crayon), tooltip: '蜡笔'),
                  ToolChip(icon: Icons.brush_rounded, selected: tool == DrawingTool.marker, onTap: () => onTool(DrawingTool.marker), tooltip: '画笔'),
                  ToolChip(icon: Icons.auto_awesome_rounded, selected: tool == DrawingTool.glow, onTap: () => onTool(DrawingTool.glow), tooltip: '闪光笔'),
                  ToolChip(icon: Icons.cleaning_services_rounded, selected: tool == DrawingTool.eraser, onTap: () => onTool(DrawingTool.eraser), tooltip: '橡皮'),
                  ToolChip(icon: Icons.undo_rounded, selected: false, onTap: canUndo ? onUndo : null, tooltip: '撤销'),
                  ToolChip(icon: Icons.redo_rounded, selected: false, onTap: canRedo ? onRedo : null, tooltip: '重做'),
                  ToolChip(icon: Icons.delete_outline_rounded, selected: false, onTap: onClear, tooltip: '清空'),
                  ToolChip(icon: Icons.save_rounded, selected: false, onTap: onSave, tooltip: '保存预览'),
                ],
              ),
              SizedBox(width: horizontal ? 14 : 0, height: horizontal ? 0 : 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final c in colors)
                    InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => onColor(c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: color == c && tool != DrawingTool.eraser ? _ink : Colors.white, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: horizontal ? 10 : 0, height: horizontal ? 0 : 8),
              SizedBox(
                width: horizontal ? 132 : double.infinity,
                child: Slider(
                  value: width,
                  min: 4,
                  max: 24,
                  divisions: 10,
                  activeColor: color,
                  onChanged: onWidth,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ToolChip extends StatelessWidget {
  const ToolChip({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: selected ? const Color(0xFFFFE3DC) : const Color(0xFFF7F0E6),
        foregroundColor: selected ? _orange : _brown,
        disabledBackgroundColor: const Color(0xFFF1E9DE),
        disabledForegroundColor: _brown.withValues(alpha: .35),
      ),
      icon: Icon(icon),
    );
  }
}

class NativeCanvasPainter extends CustomPainter {
  NativeCanvasPainter({required this.strokes});

  final List<DrawingStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    _drawPaperTexture(canvas, size);

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver;

      if (stroke.tool == DrawingTool.glow) {
        final glowPaint = Paint()
          ..color = stroke.color.withValues(alpha: .20)
          ..strokeWidth = stroke.baseWidth * 2.7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        _drawStroke(canvas, stroke, glowPaint, pressureAware: false);
      }

      paint
        ..strokeWidth = stroke.baseWidth
        ..color = stroke.tool == DrawingTool.marker ? stroke.color.withValues(alpha: .72) : stroke.color;
      _drawStroke(canvas, stroke, paint, pressureAware: stroke.tool != DrawingTool.eraser);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke, Paint paint, {required bool pressureAware}) {
    if (stroke.points.length == 1) {
      final point = stroke.points.first;
      canvas.drawCircle(point.offset, paint.strokeWidth * point.pressure / 2, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      return;
    }

    for (var i = 0; i < stroke.points.length - 1; i++) {
      final a = stroke.points[i];
      final b = stroke.points[i + 1];
      paint.strokeWidth = pressureAware ? stroke.baseWidth * ((a.pressure + b.pressure) / 2) : stroke.baseWidth;
      canvas.drawLine(a.offset, b.offset, paint);
    }
  }

  void _drawPaperTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF7EB)
      ..strokeWidth = 1;
    for (var y = 32.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NativeCanvasPainter oldDelegate) => true;
}

class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final lessons = [
      ('可爱动物', 'Cute Animals', _mint, Icons.pets_rounded),
      ('恐龙世界', 'Dinosaurs', _peach, Icons.park_rounded),
      ('交通工具', 'Vehicles', _butter, Icons.directions_car_rounded),
      ('节日快乐', 'Festivals', _rose, Icons.celebration_rounded),
    ];
    return AppPage(
      title: '跟着学画',
      onBack: onBack,
      child: ListView.separated(
        itemCount: lessons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
            child: Row(
              children: [
                Container(width: 110, height: 82, decoration: BoxDecoration(color: lesson.$3, borderRadius: BorderRadius.circular(20)), child: Icon(lesson.$4, size: 42, color: _ink)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.$1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      Text(lesson.$2, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded, color: _brown),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key, required this.sketches, required this.onBack});
  final List<RecentSketch> sketches;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '我的作品集',
      onBack: onBack,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 230, childAspectRatio: .82, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemCount: sketches.length,
        itemBuilder: (context, index) => RecentCard(sketch: sketches[index]),
      ),
    );
  }
}

class AnimationPage extends StatelessWidget {
  const AnimationPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '动画故事',
      onBack: onBack,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
              child: const Center(child: Text('✨', style: TextStyle(fontSize: 112))),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: const [
              Chip(label: Text('跳一跳')),
              Chip(label: Text('眨眼')),
              Chip(label: Text('飞起来')),
              Chip(label: Text('笔画回放')),
            ],
          ),
        ],
      ),
    );
  }
}

class ParentPage extends StatelessWidget {
  const ParentPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '家长中心',
      onBack: onBack,
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(34)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 50, color: _brown),
              SizedBox(height: 18),
              Text('Parents Only', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('What is 12 + 7?', style: TextStyle(color: _muted)),
              SizedBox(height: 18),
              FilledButton(onPressed: null, child: Text('19')),
            ],
          ),
        ),
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.title, required this.onBack, required this.child});
  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}
