import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: _orange,
          brightness: Brightness.light,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _ink,
          displayColor: _ink,
        ),
      ),
      home: const StudioHome(),
    );
  }
}

enum StudioTab { home, draw, lessons, gallery, animation, parent }

typedef SaveArtworkCallback =
    void Function(List<DrawingStroke> strokes, Size sourceSize);

const _artworkAlbumName = 'Little Art Studio';

class StudioHome extends StatefulWidget {
  const StudioHome({super.key});

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  StudioTab tab = StudioTab.home;
  final sketches = <RecentSketch>[
    RecentSketch.sample('开心的太阳', '8月10日', SketchKind.sun),
    RecentSketch.sample('我的小房子', '8月9日', SketchKind.house),
    RecentSketch.sample('打瞌睡的小猫', '8月7日', SketchKind.cat),
    RecentSketch.sample('月亮火箭', '8月5日', SketchKind.rocket),
    RecentSketch.sample('大花朵', '8月3日', SketchKind.flower),
    RecentSketch.sample('彩虹鱼', '8月1日', SketchKind.fish),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedArtworks();
  }

  Future<void> _loadSavedArtworks() async {
    final rawArtworks = await ArtworkStorage.read();
    if (rawArtworks == null) return;

    try {
      final decoded = jsonDecode(rawArtworks);
      if (decoded is! List) return;
      final savedArtworks = decoded
          .whereType<Map<String, dynamic>>()
          .map(RecentSketch.fromJson)
          .whereType<RecentSketch>()
          .toList();
      if (!mounted || savedArtworks.isEmpty) return;
      setState(() => sketches.insertAll(0, savedArtworks));
    } on FormatException {
      await ArtworkStorage.clear();
    }
  }

  Future<void> _persistSavedArtworks() async {
    final savedArtworks = sketches
        .where((sketch) => sketch.isUserDrawing)
        .map((sketch) => sketch.toJson())
        .toList();
    await ArtworkStorage.write(jsonEncode(savedArtworks));
  }

  void _saveArtwork(List<DrawingStroke> strokes, Size sourceSize) {
    final now = DateTime.now();
    setState(() {
      sketches.insert(
        0,
        RecentSketch.drawing(
          '自由创作 ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          '${now.month}月${now.day}日',
          strokes,
          sourceSize,
        ),
      );
      tab = StudioTab.gallery;
    });
    _persistSavedArtworks();
  }

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
          StudioTab.draw => DrawPage(
            onBack: () => setState(() => tab = StudioTab.home),
            onSaveArtwork: _saveArtwork,
          ),
          StudioTab.lessons => LessonsPage(
            onBack: () => setState(() => tab = StudioTab.home),
          ),
          StudioTab.gallery => GalleryPage(
            sketches: sketches,
            onBack: () => setState(() => tab = StudioTab.home),
          ),
          StudioTab.animation => AnimationPage(
            sketches: sketches,
            onBack: () => setState(() => tab = StudioTab.home),
          ),
          StudioTab.parent => ParentPage(
            onBack: () => setState(() => tab = StudioTab.home),
          ),
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
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 1080 : 520,
                      ),
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
          NavPill(
            icon: Icons.translate_rounded,
            label: 'EN',
            selected: false,
            onTap: () {},
          ),
          NavPill(
            icon: Icons.verified_user_outlined,
            label: '家长',
            selected: selected == StudioTab.parent,
            onTap: () => onSelect(StudioTab.parent),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class NavPill extends StatelessWidget {
  const NavPill({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
              Text(
                label,
                style: TextStyle(
                  color: selected ? _orange : _brown,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudioBottomNav extends StatelessWidget {
  const StudioBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

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
        selectedIndex: math.max(
          0,
          items.indexWhere((item) => item.$1 == selected),
        ),
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
          padding: EdgeInsets.fromLTRB(
            isTablet ? 26 : 20,
            isTablet ? 20 : 24,
            isTablet ? 28 : 0,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeroGreeting(onParent: () => onOpen(StudioTab.parent)),
              SizedBox(height: isTablet ? 30 : 42),
              Text(
                '今天想做什么？',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 34,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: isTablet ? 18 : 20,
                crossAxisSpacing: isTablet ? 18 : 20,
                childAspectRatio: isTablet ? 2.35 : .98,
                children: [
                  ActionTile(
                    title: '自由画画',
                    subtitle: '随心创作',
                    icon: Icons.palette_rounded,
                    iconColor: _orange,
                    color: _peach,
                    onTap: () => onOpen(StudioTab.draw),
                  ),
                  ActionTile(
                    title: '跟着学画',
                    subtitle: '一步一步学',
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF07523E),
                    color: _mint,
                    onTap: () => onOpen(StudioTab.lessons),
                  ),
                  ActionTile(
                    title: '我的作品集',
                    subtitle: '你的画作',
                    icon: Icons.photo_library_rounded,
                    iconColor: const Color(0xFF6E3D00),
                    color: _butter,
                    onTap: () => onOpen(StudioTab.gallery),
                  ),
                  ActionTile(
                    title: '动画故事',
                    subtitle: '让画动起来',
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFF5B285F),
                    color: _rose,
                    onTap: () => onOpen(StudioTab.animation),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 32 : 34),
              Row(
                children: [
                  Text(
                    '最近画的',
                    style: TextStyle(
                      fontSize: isTablet ? 21 : 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => onOpen(StudioTab.gallery),
                    child: const Text(
                      '查看全部',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: isTablet ? 180 : 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sketches.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) =>
                      RecentCard(sketch: sketches[index], compact: isTablet),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 44,
                backgroundColor: Color(0xFFFFDD78),
                child: Text('🦊', style: TextStyle(fontSize: 38)),
              ),
              Positioned(
                right: -4,
                top: -8,
                child: _Dot(color: const Color(0xFFFFDD78), size: 16),
              ),
              Positioned(
                left: 10,
                bottom: -8,
                child: _Dot(color: const Color(0xFFE6B4EF), size: 14),
              ),
            ],
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '你好，',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '米娅!',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF2E9DE),
              foregroundColor: _ink,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: () {},
            icon: const Icon(Icons.translate_rounded),
            label: const Text(
              'EN',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF2E9DE),
              foregroundColor: _brown,
            ),
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
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.color,
    required this.onTap,
  });

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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E5A45).withValues(alpha: .18),
                blurRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Icon(icon, color: iconColor, size: 32),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 17,
                      color: _muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SketchKind { sun, house, cat, rocket, flower, fish }

class RecentSketch {
  const RecentSketch.sample(this.title, this.date, this.kind)
    : strokes = null,
      sourceSize = null;

  const RecentSketch.drawing(
    this.title,
    this.date,
    this.strokes,
    this.sourceSize,
  ) : kind = null;

  factory RecentSketch.fromJson(Map<String, dynamic> json) {
    final width = (json['sourceWidth'] as num?)?.toDouble();
    final height = (json['sourceHeight'] as num?)?.toDouble();
    final strokesJson = json['strokes'];
    if (width == null || height == null || strokesJson is! List) {
      throw const FormatException('Invalid saved artwork');
    }

    return RecentSketch.drawing(
      json['title'] as String? ?? '自由创作',
      json['date'] as String? ?? '',
      strokesJson
          .whereType<Map<String, dynamic>>()
          .map(DrawingStroke.fromJson)
          .toList(),
      Size(width, height),
    );
  }

  final String title;
  final String date;
  final SketchKind? kind;
  final List<DrawingStroke>? strokes;
  final Size? sourceSize;

  bool get isUserDrawing => strokes != null && sourceSize != null;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'sourceWidth': sourceSize?.width,
      'sourceHeight': sourceSize?.height,
      'strokes': strokes?.map((stroke) => stroke.toJson()).toList() ?? const [],
    };
  }
}

class RecentCard extends StatelessWidget {
  const RecentCard({
    super.key,
    required this.sketch,
    this.compact = false,
    this.onTap,
  });

  final RecentSketch sketch;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(34),
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
        child: Container(
          width: compact ? 160 : 258,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomPaint(
                  painter: sketch.strokes == null
                      ? SketchPainter(sketch.kind ?? SketchKind.sun)
                      : ArtworkPreviewPainter(
                          strokes: sketch.strokes!,
                          sourceSize: sketch.sourceSize ?? const Size(800, 600),
                        ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sketch.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 14 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!compact)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE3DC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: _orange,
                      ),
                    ),
                ],
              ),
              if (!compact)
                Text(
                  sketch.date,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArtworkPreview extends StatelessWidget {
  const ArtworkPreview({super.key, required this.sketch});

  final RecentSketch sketch;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: sketch.strokes == null
          ? SketchPainter(sketch.kind ?? SketchKind.sun)
          : ArtworkPreviewPainter(
              strokes: sketch.strokes!,
              sourceSize: sketch.sourceSize ?? const Size(800, 600),
            ),
      child: const SizedBox.expand(),
    );
  }
}

class ArtworkPreviewPainter extends CustomPainter {
  ArtworkPreviewPainter({required this.strokes, required this.sourceSize});

  final List<DrawingStroke> strokes;
  final Size sourceSize;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / sourceSize.width,
      size.height / sourceSize.height,
    );
    final dx = (size.width - sourceSize.width * scale) / 2;
    final dy = (size.height - sourceSize.height * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    NativeCanvasPainter(strokes: strokes).paint(canvas, sourceSize);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArtworkPreviewPainter oldDelegate) => true;
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
          canvas.drawLine(
            c + Offset(math.cos(a), math.sin(a)) * size.shortestSide * .36,
            c + Offset(math.cos(a), math.sin(a)) * size.shortestSide * .48,
            ray,
          );
        }
      case SketchKind.house:
        canvas.drawRect(
          Rect.fromCenter(
            center: c + const Offset(0, 18),
            width: size.width * .42,
            height: size.height * .36,
          ),
          Paint()..color = const Color(0xFF7ED3CE),
        );
        final roof = Path()
          ..moveTo(c.dx - size.width * .28, c.dy)
          ..lineTo(c.dx, c.dy - size.height * .28)
          ..lineTo(c.dx + size.width * .28, c.dy)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFF56B5E8));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c + Offset(0, size.height * .2),
              width: 34,
              height: 58,
            ),
            const Radius.circular(8),
          ),
          Paint()..color = Colors.white,
        );
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
        canvas.drawArc(
          Rect.fromCenter(
            center: c + const Offset(0, 16),
            width: 42,
            height: 24,
          ),
          0,
          math.pi,
          false,
          Paint()
            ..color = _ink
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke,
        );
      case SketchKind.rocket:
        final body = Path()
          ..moveTo(c.dx, c.dy - size.height * .34)
          ..quadraticBezierTo(c.dx + 36, c.dy - 4, c.dx + 18, c.dy + 54)
          ..lineTo(c.dx - 18, c.dy + 54)
          ..quadraticBezierTo(
            c.dx - 36,
            c.dy - 4,
            c.dx,
            c.dy - size.height * .34,
          )
          ..close();
        canvas.drawPath(body, Paint()..color = const Color(0xFF82A8FF));
        canvas.drawCircle(
          c + const Offset(0, -22),
          13,
          Paint()..color = Colors.white,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 18, c.dy + 42)
            ..lineTo(c.dx - 52, c.dy + 72)
            ..lineTo(c.dx - 8, c.dy + 60)
            ..close(),
          Paint()..color = const Color(0xFF8D8AF9),
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + 18, c.dy + 42)
            ..lineTo(c.dx + 52, c.dy + 72)
            ..lineTo(c.dx + 8, c.dy + 60)
            ..close(),
          Paint()..color = const Color(0xFF8D8AF9),
        );
      case SketchKind.flower:
        final petal = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFA0BF), Color(0xFFFFE0A3)],
          ).createShader(Offset.zero & size);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          canvas.drawCircle(
            c + Offset(math.cos(a), math.sin(a)) * size.shortestSide * .18,
            size.shortestSide * .13,
            petal,
          );
        }
        canvas.drawCircle(
          c,
          size.shortestSide * .12,
          Paint()..color = const Color(0xFFE77BD6),
        );
        canvas.drawLine(
          c + Offset(0, size.shortestSide * .12),
          c + Offset(0, size.shortestSide * .44),
          Paint()
            ..color = const Color(0xFF59A463)
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round,
        );
      case SketchKind.fish:
        canvas.drawOval(
          Rect.fromCenter(
            center: c,
            width: size.width * .52,
            height: size.height * .32,
          ),
          Paint()..color = const Color(0xFF77DCC4),
        );
        final tail = Path()
          ..moveTo(c.dx + size.width * .26, c.dy)
          ..lineTo(c.dx + size.width * .46, c.dy - size.height * .18)
          ..lineTo(c.dx + size.width * .46, c.dy + size.height * .18)
          ..close();
        canvas.drawPath(tail, Paint()..color = const Color(0xFF74C9F5));
        canvas.drawCircle(
          c + Offset(-size.width * .18, -size.height * .04),
          7,
          Paint()..color = _ink,
        );
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

class DrawPage extends StatefulWidget {
  const DrawPage({
    super.key,
    required this.onBack,
    required this.onSaveArtwork,
  });
  final VoidCallback onBack;
  final SaveArtworkCallback onSaveArtwork;

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
      _activeStroke?.points.add(
        DrawingPoint(event.localPosition, _pressure(event)),
      );
    });
  }

  void _endStroke(PointerEvent event) {
    _activeStroke = null;
  }

  double _pressure(PointerEvent event) {
    if (event.kind != ui.PointerDeviceKind.stylus &&
        event.kind != ui.PointerDeviceKind.invertedStylus) {
      return 1;
    }
    if (event.pressureMax <= event.pressureMin) {
      return 1;
    }
    return ((event.pressure - event.pressureMin) /
            (event.pressureMax - event.pressureMin))
        .clamp(.35, 1.4);
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
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('先画一点东西再保存吧'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    final bytes = data?.buffer.asUint8List();
    if (bytes == null) return;
    final sizeKb = (bytes.lengthInBytes / 1024).round();
    final fileName = 'little_artist_${DateTime.now().millisecondsSinceEpoch}';
    var exportedToGallery = false;
    try {
      await GalleryExporter.savePng(bytes, name: fileName);
      exportedToGallery = true;
    } catch (_) {
      exportedToGallery = false;
    }
    widget.onSaveArtwork(
      _strokes.map((stroke) => stroke.copy()).toList(),
      boundary.size,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          exportedToGallery
              ? '已保存到作品集，并导出 PNG 到相册，约 $sizeKb KB'
              : '已保存到作品集。相册权限开启后可导出 PNG',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      _orange,
      const Color(0xFFFF9D00),
      const Color(0xFFFFCA5C),
      const Color(0xFF6BDBA4),
      const Color(0xFF30C99A),
      const Color(0xFF45B6E8),
      const Color(0xFF5B6DEE),
      const Color(0xFFB36DF2),
      const Color(0xFFE95DA8),
      const Color(0xFF9A765E),
      const Color(0xFF101827),
      Colors.white,
    ];
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
              SizedBox(width: isWide ? 112 : double.infinity, child: tools),
              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 14),
              Expanded(child: canvas),
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

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      Offset(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
      ),
      (json['pressure'] as num?)?.toDouble() ?? 1,
    );
  }

  final Offset offset;
  final double pressure;

  Map<String, dynamic> toJson() {
    return {'x': offset.dx, 'y': offset.dy, 'pressure': pressure};
  }
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

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final toolName = json['tool'] as String?;
    final pointsJson = json['points'];
    return DrawingStroke(
      tool: DrawingTool.values.firstWhere(
        (tool) => tool.name == toolName,
        orElse: () => DrawingTool.crayon,
      ),
      color: Color((json['color'] as num?)?.toInt() ?? _orange.toARGB32()),
      baseWidth: (json['baseWidth'] as num?)?.toDouble() ?? 12,
      points: pointsJson is List
          ? pointsJson
                .whereType<Map<String, dynamic>>()
                .map(DrawingPoint.fromJson)
                .toList()
          : <DrawingPoint>[],
    );
  }

  DrawingStroke copy() {
    return DrawingStroke(
      tool: tool,
      color: color,
      baseWidth: baseWidth,
      points: List<DrawingPoint>.from(points),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tool': tool.name,
      'color': color.toARGB32(),
      'baseWidth': baseWidth,
      'points': points.map((point) => point.toJson()).toList(),
    };
  }
}

class GalleryExporter {
  const GalleryExporter._();

  static Future<void> savePng(Uint8List bytes, {required String name}) async {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    final isGranted = hasAccess || await Gal.requestAccess(toAlbum: true);
    if (!isGranted) {
      throw Exception('相册权限未开启');
    }
    await Gal.putImageBytes(bytes, album: _artworkAlbumName, name: name);
  }
}

class ArtworkStorage {
  const ArtworkStorage._();

  static const _channel = MethodChannel('little_artist/storage');

  static Future<String?> read() async {
    try {
      return await _channel.invokeMethod<String>('readSavedArtworks');
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> write(String json) async {
    try {
      await _channel.invokeMethod<void>('writeSavedArtworks', json);
    } on MissingPluginException {
      // Persistence is provided by the mobile shell; web/tests can keep running without it.
    }
  }

  static Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clearSavedArtworks');
    } on MissingPluginException {
      // Persistence is provided by the mobile shell; web/tests can keep running without it.
    }
  }
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
                  ToolChip(
                    icon: Icons.edit_rounded,
                    selected: tool == DrawingTool.crayon,
                    onTap: () => onTool(DrawingTool.crayon),
                    tooltip: '蜡笔',
                  ),
                  ToolChip(
                    icon: Icons.brush_rounded,
                    selected: tool == DrawingTool.marker,
                    onTap: () => onTool(DrawingTool.marker),
                    tooltip: '画笔',
                  ),
                  ToolChip(
                    icon: Icons.auto_awesome_rounded,
                    selected: tool == DrawingTool.glow,
                    onTap: () => onTool(DrawingTool.glow),
                    tooltip: '闪光笔',
                  ),
                  ToolChip(
                    icon: Icons.cleaning_services_rounded,
                    selected: tool == DrawingTool.eraser,
                    onTap: () => onTool(DrawingTool.eraser),
                    tooltip: '橡皮',
                  ),
                  ToolChip(
                    icon: Icons.undo_rounded,
                    selected: false,
                    onTap: canUndo ? onUndo : null,
                    tooltip: '撤销',
                  ),
                  ToolChip(
                    icon: Icons.redo_rounded,
                    selected: false,
                    onTap: canRedo ? onRedo : null,
                    tooltip: '重做',
                  ),
                  ToolChip(
                    icon: Icons.delete_outline_rounded,
                    selected: false,
                    onTap: onClear,
                    tooltip: '清空',
                  ),
                  ToolChip(
                    icon: Icons.save_rounded,
                    selected: false,
                    onTap: onSave,
                    tooltip: '保存预览',
                  ),
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
                          border: Border.all(
                            color: color == c && tool != DrawingTool.eraser
                                ? _ink
                                : Colors.white,
                            width: 3,
                          ),
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
        backgroundColor: selected
            ? const Color(0xFFFFE3DC)
            : const Color(0xFFF7F0E6),
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
        ..color = stroke.tool == DrawingTool.marker
            ? stroke.color.withValues(alpha: .72)
            : stroke.color;
      _drawStroke(
        canvas,
        stroke,
        paint,
        pressureAware: stroke.tool != DrawingTool.eraser,
      );
    }
  }

  void _drawStroke(
    Canvas canvas,
    DrawingStroke stroke,
    Paint paint, {
    required bool pressureAware,
  }) {
    if (stroke.points.length == 1) {
      final point = stroke.points.first;
      canvas.drawCircle(
        point.offset,
        paint.strokeWidth * point.pressure / 2,
        paint..style = PaintingStyle.fill,
      );
      paint.style = PaintingStyle.stroke;
      return;
    }

    for (var i = 0; i < stroke.points.length - 1; i++) {
      final a = stroke.points[i];
      final b = stroke.points[i + 1];
      paint.strokeWidth = pressureAware
          ? stroke.baseWidth * ((a.pressure + b.pressure) / 2)
          : stroke.baseWidth;
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

class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  LessonTopic? selectedTopic;
  int step = 1;

  @override
  Widget build(BuildContext context) {
    final lessons = [
      LessonTopic('小动物', '12 节课', _peach, Icons.pets_rounded, 1),
      LessonTopic('恐龙', '8 节课', _mint, Icons.park_rounded, 2),
      LessonTopic('交通工具', '10 节课', _butter, Icons.directions_car_rounded, 2),
      LessonTopic('节日', '6 节课', _rose, Icons.celebration_rounded, 3),
    ];

    if (selectedTopic != null) {
      final topic = selectedTopic!;
      return AppPage(
        title: topic.title,
        onBack: () => setState(() {
          selectedTopic = null;
          step = 1;
        }),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: CustomPaint(
                  painter: LessonStepPainter(topic: topic, step: step),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: step / 6,
              minHeight: 12,
              borderRadius: BorderRadius.circular(99),
              color: _orange,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: step > 1 ? () => setState(() => step--) : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('上一步'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('语音提示'),
                ),
                FilledButton.icon(
                  onPressed: step < 6
                      ? () => setState(() => step++)
                      : widget.onBack,
                  icon: Icon(
                    step < 6
                        ? Icons.arrow_forward_rounded
                        : Icons.palette_rounded,
                  ),
                  label: Text(step < 6 ? '下一步' : '去上色'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppPage(
      title: '跟着学画',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选一个主题，一步一步画。',
            style: TextStyle(color: _muted, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              itemCount: lessons.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 520,
                childAspectRatio: 1.85,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return LessonTopicCard(
                  topic: lesson,
                  onTap: () => setState(() {
                    selectedTopic = lesson;
                    step = 1;
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LessonTopic {
  const LessonTopic(this.title, this.count, this.color, this.icon, this.stars);

  final String title;
  final String count;
  final Color color;
  final IconData icon;
  final int stars;
}

class LessonTopicCard extends StatelessWidget {
  const LessonTopicCard({super.key, required this.topic, required this.onTap});

  final LessonTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(34),
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: topic.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                ),
                child: Center(child: Icon(topic.icon, size: 58, color: _ink)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          topic.count,
                          style: const TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < 3; i++)
                    Icon(
                      Icons.star_rounded,
                      color: i < topic.stars
                          ? const Color(0xFFFFB22E)
                          : const Color(0xFFE8DAC6),
                      size: 19,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonStepPainter extends CustomPainter {
  LessonStepPainter({required this.topic, required this.step});

  final LessonTopic topic;
  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = _orange
      ..strokeWidth = size.shortestSide * .035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final faint = Paint()
      ..color = _brown.withValues(alpha: .16)
      ..strokeWidth = size.shortestSide * .028
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final text = TextPainter(
      text: TextSpan(
        text: '第 $step 步 / 共 6 步',
        style: const TextStyle(
          color: _ink,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(28, 24));

    void drawWhen(int minStep, VoidCallback draw) {
      final previous = paint.color;
      paint.color = step >= minStep ? _orange : _brown.withValues(alpha: .16);
      draw();
      paint.color = previous;
    }

    drawWhen(
      1,
      () => canvas.drawCircle(center, size.shortestSide * .16, paint),
    );
    drawWhen(2, () {
      canvas.drawCircle(
        center + Offset(-size.width * .05, -size.height * .02),
        6,
        Paint()..color = _ink,
      );
      canvas.drawCircle(
        center + Offset(size.width * .05, -size.height * .02),
        6,
        Paint()..color = _ink,
      );
    });
    drawWhen(
      3,
      () => canvas.drawArc(
        Rect.fromCenter(
          center: center + Offset(0, size.height * .04),
          width: 70,
          height: 40,
        ),
        0,
        math.pi,
        false,
        paint,
      ),
    );
    drawWhen(4, () {
      canvas.drawLine(
        center + Offset(-size.width * .16, -size.height * .04),
        center + Offset(-size.width * .24, -size.height * .16),
        paint,
      );
      canvas.drawLine(
        center + Offset(size.width * .16, -size.height * .04),
        center + Offset(size.width * .24, -size.height * .16),
        paint,
      );
    });
    drawWhen(5, () {
      canvas.drawLine(
        center + Offset(-size.width * .08, size.height * .16),
        center + Offset(-size.width * .12, size.height * .30),
        paint,
      );
      canvas.drawLine(
        center + Offset(size.width * .08, size.height * .16),
        center + Offset(size.width * .12, size.height * .30),
        paint,
      );
    });
    if (step < 6) {
      canvas.drawCircle(
        center + Offset(size.width * .26, 0),
        size.shortestSide * .08,
        faint,
      );
    } else {
      canvas.drawCircle(
        center + Offset(size.width * .26, 0),
        size.shortestSide * .08,
        Paint()..color = topic.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LessonStepPainter oldDelegate) =>
      oldDelegate.step != step || oldDelegate.topic != topic;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sketches.length} 幅作品 · 只有你和家长能看到',
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                childAspectRatio: .82,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
              ),
              itemCount: sketches.length,
              itemBuilder: (context, index) {
                final sketch = sketches[index];
                return RecentCard(
                  sketch: sketch,
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    backgroundColor: _bg,
                    builder: (context) => ArtworkDetailSheet(sketch: sketch),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ArtworkDetailSheet extends StatefulWidget {
  const ArtworkDetailSheet({super.key, required this.sketch});

  final RecentSketch sketch;

  @override
  State<ArtworkDetailSheet> createState() => _ArtworkDetailSheetState();
}

class _ArtworkDetailSheetState extends State<ArtworkDetailSheet> {
  final _previewKey = GlobalKey();

  Future<void> _exportPng() async {
    final boundary =
        _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data?.buffer.asUint8List();
    if (bytes == null) return;

    try {
      await GalleryExporter.savePng(
        bytes,
        name: 'little_artist_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PNG 已导出到相册'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('导出失败，请确认相册权限已开启'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sketch = widget.sketch;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sketch.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                sketch.date,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RepaintBoundary(
              key: _previewKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: ArtworkPreview(sketch: sketch),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('播放回放'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('生成动画'),
              ),
              FilledButton.tonalIcon(
                onPressed: _exportPng,
                icon: const Icon(Icons.download_rounded),
                label: const Text('导出 PNG'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('分享给家长'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('关闭'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimationPage extends StatefulWidget {
  const AnimationPage({
    super.key,
    required this.sketches,
    required this.onBack,
  });
  final List<RecentSketch> sketches;
  final VoidCallback onBack;

  @override
  State<AnimationPage> createState() => _AnimationPageState();
}

class _AnimationPageState extends State<AnimationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  int selectedSketch = 0;
  String selectedEffect = '弹跳';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sketches = widget.sketches;
    final sketch = sketches[selectedSketch.clamp(0, sketches.length - 1)];
    final effects = [
      (Icons.keyboard_double_arrow_up_rounded, '弹跳'),
      (Icons.auto_awesome_rounded, '闪烁'),
      (Icons.flight_takeoff_rounded, '飞翔'),
      (Icons.draw_rounded, '笔迹重播'),
    ];
    return AppPage(
      title: '动画故事',
      onBack: widget.onBack,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final preview = Container(
            padding: const EdgeInsets.all(34),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(38),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final t = controller.value;
                final offset = selectedEffect == '弹跳'
                    ? Offset(0, -24 * math.sin(t * math.pi))
                    : selectedEffect == '飞翔'
                    ? Offset(
                        30 * math.sin(t * math.pi * 2),
                        -10 * math.sin(t * math.pi),
                      )
                    : Offset.zero;
                final opacity = selectedEffect == '闪烁' ? .55 + .45 * t : 1.0;
                final scale = selectedEffect == '笔迹重播' ? .92 + .08 * t : 1.0;
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: offset,
                    child: Transform.scale(scale: scale, child: child),
                  ),
                );
              },
              child: ArtworkPreview(sketch: sketch),
            ),
          );
          final controls = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选一幅画，让它动起来。',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 22),
              const Text(
                '1. 选一幅画',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sketches.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => setState(() => selectedSketch = index),
                      child: Container(
                        width: 96,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: selectedSketch == index
                                ? _orange
                                : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: ArtworkPreview(sketch: sketches[index]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '2. 选一个效果',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 4.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  for (final effect in effects)
                    ChoiceChip(
                      avatar: Icon(
                        effect.$1,
                        color: selectedEffect == effect.$2 ? _ink : _orange,
                      ),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          effect.$2,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      selected: selectedEffect == effect.$2,
                      selectedColor: const Color(0xFF77DDB4),
                      backgroundColor: Colors.white,
                      onSelected: (_) =>
                          setState(() => selectedEffect = effect.$2),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('保存动画'),
                ),
              ),
            ],
          );
          return wide
              ? Row(
                  children: [
                    Expanded(flex: 4, child: preview),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(child: controls),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: preview),
                    const SizedBox(height: 18),
                    Expanded(child: SingleChildScrollView(child: controls)),
                  ],
                );
        },
      ),
    );
  }
}

class ParentPage extends StatefulWidget {
  const ParentPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  final answer = TextEditingController();
  bool verified = false;
  double minutes = 25;
  String ageMode = '5-8 岁';

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (verified) {
      return AppPage(
        title: '家长中心',
        onBack: widget.onBack,
        child: ListView(
          children: [
            ParentSettingCard(
              icon: Icons.timer_rounded,
              title: '每日使用时长',
              subtitle: '${minutes.round()} 分钟',
              trailing: SizedBox(
                width: 260,
                child: Slider(
                  value: minutes,
                  min: 10,
                  max: 60,
                  divisions: 5,
                  activeColor: _orange,
                  onChanged: (value) => setState(() => minutes = value),
                ),
              ),
            ),
            ParentSettingCard(
              icon: Icons.child_care_rounded,
              title: '年龄模式',
              subtitle: ageMode,
              trailing: DropdownButton<String>(
                value: ageMode,
                items: const ['3-4 岁', '5-8 岁', '9-10 岁']
                    .map(
                      (age) => DropdownMenuItem(value: age, child: Text(age)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => ageMode = value ?? ageMode),
              ),
            ),
            const ParentSettingCard(
              icon: Icons.visibility_off_rounded,
              title: '护眼提醒',
              subtitle: '每 20 分钟提醒休息',
            ),
            const ParentSettingCard(
              icon: Icons.lock_rounded,
              title: '隐私保护',
              subtitle: '作品仅本地保存，默认不公开',
            ),
            const ParentSettingCard(
              icon: Icons.inventory_2_rounded,
              title: '素材包管理',
              subtitle: '动物、恐龙、交通、节日',
            ),
          ],
        ),
      );
    }

    return AppPage(
      title: '返回儿童模式',
      onBack: widget.onBack,
      child: Center(
        child: Container(
          width: 390,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Icon(Icons.verified_user_outlined, size: 50, color: _brown),
              const SizedBox(height: 10),
              const Text(
                '家长验证',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text('回答问题即可进入家长中心。', style: TextStyle(color: _muted)),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '9 × 10 等于多少？',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: answer,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '答案',
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: _orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: _orange, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3E5A78),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (answer.text.trim() == '90') {
                      setState(() => verified = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('答案不对，请再试一次')),
                      );
                    }
                  },
                  child: const Text('继续'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentSettingCard extends StatelessWidget {
  const ParentSettingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFE3DC),
            child: Icon(icon, color: _orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
  });
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
              IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}
