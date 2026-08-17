import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lovable_little_artist/local_artist_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const LittleArtistVerseApp());
}

const _bg = Color(0xFFFFF9EC);
const _ink = Color(0xFF3A1D10);
const _muted = Color(0xFF8A6D5E);
const _peach = Color(0xFFF9DDD1);
const _mint = Color(0xFFD2F2DC);
const _butter = Color(0xFFFFEAB0);
const _rose = Color(0xFFF2DEE8);
const _orange = Color(0xFFFF6B53);
const _brown = Color(0xFF8A6D5E);

void _ignoreStorageError(Future<void> operation) {
  unawaited(operation.catchError((Object _) {}));
}

class LittleArtistVerseApp extends StatelessWidget {
  const LittleArtistVerseApp({super.key, this.store});

  final ArtistStore? store;

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
      home: StudioHome(store: store ?? LocalArtistStore()),
    );
  }
}

enum StudioTab { home, draw, lessons, gallery, animation, parent }

class StudioHome extends StatefulWidget {
  const StudioHome({super.key, required this.store});

  final ArtistStore store;

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  StudioTab tab = StudioTab.home;
  int _nextArtworkNumber = 1;
  final Map<String, int> _lessonProgress = {};
  final sketches = const [
    RecentSketch('开心的太阳', SketchKind.sun),
    RecentSketch('我的小房子', SketchKind.house),
    RecentSketch('打瞌睡的小猫', SketchKind.cat),
    RecentSketch('月亮火箭', SketchKind.rocket),
  ];
  final artworks = <GalleryArtwork>[
    const GalleryArtwork(
      id: 'sun',
      title: '开心的太阳',
      createdLabel: '今天',
      color: _butter,
      kind: SketchKind.sun,
    ),
    const GalleryArtwork(
      id: 'house',
      title: '我的小房子',
      createdLabel: '昨天',
      color: _mint,
      kind: SketchKind.house,
    ),
    const GalleryArtwork(
      id: 'cat',
      title: '打瞌睡的小猫',
      createdLabel: '3 天前',
      color: _peach,
      kind: SketchKind.cat,
    ),
    const GalleryArtwork(
      id: 'rocket',
      title: '月亮火箭',
      createdLabel: '上周',
      color: _rose,
      kind: SketchKind.rocket,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _restoreLocalState();
  }

  Future<void> _restoreLocalState() async {
    final snapshot = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _nextArtworkNumber = snapshot.nextArtworkNumber;
      _lessonProgress
        ..clear()
        ..addAll(snapshot.lessonProgress);
      artworks.insertAll(0, snapshot.artworks.map(_galleryArtworkFromStored));
    });
  }

  Future<void> _addArtwork(Uint8List pngBytes) async {
    final now = DateTime.now();
    final id = 'drawing-${now.microsecondsSinceEpoch}';
    final artwork = GalleryArtwork(
      id: id,
      title: '我的画作 $_nextArtworkNumber',
      createdLabel: '刚刚',
      createdAt: now,
      color: _mint,
      pngBytes: pngBytes,
      isUserCreated: true,
      source: 'free',
    );
    await widget.store.saveArtwork(_storedArtworkFromGallery(artwork));
    if (!mounted) return;
    setState(() {
      _nextArtworkNumber++;
      artworks.insert(0, artwork);
    });
  }

  Future<void> _addLessonArtwork(
    DrawingLesson lesson,
    Uint8List pngBytes,
  ) async {
    final now = DateTime.now();
    final id = 'lesson-${lesson.id}-${now.microsecondsSinceEpoch}';
    final artwork = GalleryArtwork(
      id: id,
      title: '课程作品 · ${lesson.title}',
      createdLabel: '刚刚',
      createdAt: now,
      color: lesson.color,
      pngBytes: pngBytes,
      isUserCreated: true,
      source: 'lesson',
      lessonId: lesson.id,
    );
    await widget.store.saveArtwork(_storedArtworkFromGallery(artwork));
    if (!mounted) return;
    setState(() {
      _nextArtworkNumber++;
      artworks.insert(0, artwork);
    });
  }

  void _updateLessonProgress(String lessonId, int completedSteps) {
    setState(() => _lessonProgress[lessonId] = completedSteps);
    _ignoreStorageError(widget.store.saveLessonProgress(_lessonProgress));
  }

  void _toggleArtworkFavorite(String id) {
    final index = artworks.indexWhere((artwork) => artwork.id == id);
    if (index < 0) return;
    final updated = artworks[index].copyWith(
      isFavorite: !artworks[index].isFavorite,
    );
    setState(() => artworks[index] = updated);
    if (updated.isUserCreated) {
      _ignoreStorageError(
        widget.store.updateArtwork(_storedArtworkFromGallery(updated)),
      );
    }
  }

  void _renameArtwork(String id, String title) {
    final index = artworks.indexWhere((artwork) => artwork.id == id);
    if (index < 0) return;
    final updated = artworks[index].copyWith(title: title);
    setState(() => artworks[index] = updated);
    if (updated.isUserCreated) {
      _ignoreStorageError(
        widget.store.updateArtwork(_storedArtworkFromGallery(updated)),
      );
    }
  }

  void _deleteArtwork(String id) {
    setState(() => artworks.removeWhere((artwork) => artwork.id == id));
    _ignoreStorageError(widget.store.deleteArtwork(id));
  }

  GalleryArtwork _galleryArtworkFromStored(StoredArtwork stored) =>
      GalleryArtwork(
        id: stored.id,
        title: stored.title,
        createdLabel: _relativeDate(stored.createdAt),
        createdAt: stored.createdAt,
        color: Color(stored.backgroundColor),
        pngBytes: stored.pngBytes,
        isFavorite: stored.isFavorite,
        isUserCreated: true,
        source: stored.source,
        lessonId: stored.lessonId,
      );

  StoredArtwork _storedArtworkFromGallery(GalleryArtwork artwork) =>
      StoredArtwork(
        id: artwork.id,
        title: artwork.title,
        createdAt: artwork.createdAt ?? DateTime.now(),
        fileName: '${artwork.id}.png',
        isFavorite: artwork.isFavorite,
        source: artwork.source,
        backgroundColor: artwork.color.toARGB32(),
        pngBytes: artwork.pngBytes!,
        lessonId: artwork.lessonId,
      );

  String _relativeDate(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 2) return '刚刚';
    if (difference.inHours < 24) return '${difference.inHours} 小时前';
    if (difference.inDays == 1) return '昨天';
    if (difference.inDays < 7) return '${difference.inDays} 天前';
    return '${createdAt.month} 月 ${createdAt.day} 日';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet =
            constraints.biggest.shortestSide >= 600 &&
            constraints.maxHeight >= 700;
        final content = switch (tab) {
          StudioTab.home => Dashboard(
            sketches: sketches,
            onOpen: (next) => setState(() => tab = next),
          ),
          StudioTab.draw => DrawPage(
            onBack: () => setState(() => tab = StudioTab.home),
            onSaved: _addArtwork,
            store: widget.store,
          ),
          StudioTab.lessons => LessonsPage(
            onBack: () => setState(() => tab = StudioTab.home),
            progress: _lessonProgress,
            onProgress: _updateLessonProgress,
            onArtworkSaved: _addLessonArtwork,
            store: widget.store,
          ),
          StudioTab.gallery => GalleryPage(
            artworks: artworks,
            onBack: () => setState(() => tab = StudioTab.home),
            onCreateNew: () => setState(() => tab = StudioTab.draw),
            onToggleFavorite: _toggleArtworkFavorite,
            onRename: _renameArtwork,
            onDelete: _deleteArtwork,
          ),
          StudioTab.animation => AnimationPage(
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

enum SketchKind { sun, house, cat, rocket }

class RecentSketch {
  const RecentSketch(this.title, this.kind);
  final String title;
  final SketchKind kind;
}

class GalleryArtwork {
  const GalleryArtwork({
    required this.id,
    required this.title,
    required this.createdLabel,
    required this.color,
    this.kind,
    this.pngBytes,
    this.isFavorite = false,
    this.isUserCreated = false,
    this.createdAt,
    this.source = 'sample',
    this.lessonId,
  });

  final String id;
  final String title;
  final String createdLabel;
  final Color color;
  final SketchKind? kind;
  final Uint8List? pngBytes;
  final bool isFavorite;
  final bool isUserCreated;
  final DateTime? createdAt;
  final String source;
  final String? lessonId;

  GalleryArtwork copyWith({String? title, bool? isFavorite}) {
    return GalleryArtwork(
      id: id,
      title: title ?? this.title,
      createdLabel: createdLabel,
      color: color,
      kind: kind,
      pngBytes: pngBytes,
      isFavorite: isFavorite ?? this.isFavorite,
      isUserCreated: isUserCreated,
      createdAt: createdAt,
      source: source,
      lessonId: lessonId,
    );
  }
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
              painter: SketchPainter(sketch.kind),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sketch.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 14 : 23,
              fontWeight: FontWeight.w900,
            ),
          ),
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
    required this.onSaved,
    required this.store,
  });
  final VoidCallback onBack;
  final Future<void> Function(Uint8List) onSaved;
  final ArtistStore store;

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
  Timer? _autosaveTimer;
  bool _draftRestored = false;

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    if (_strokes.isNotEmpty) _ignoreStorageError(_persistDraft());
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await widget.store.loadDraft('free-drawing');
    if (!mounted) return;
    final restored = _strokesFromDraft(draft);
    setState(() {
      _strokes
        ..clear()
        ..addAll(restored);
      _draftRestored = restored.isNotEmpty;
    });
    if (_draftRestored) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已恢复上次自动保存的草稿'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 700), _persistDraft);
  }

  Future<void> _persistDraft() async {
    try {
      if (_strokes.isEmpty) {
        await widget.store.deleteDraft('free-drawing');
        return;
      }
      await widget.store.saveDraft('free-drawing', _draftFromStrokes(_strokes));
    } catch (_) {
      // A failed autosave must never interrupt drawing.
    }
  }

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
    _scheduleAutosave();
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
    _scheduleAutosave();
  }

  void _redo() {
    if (!_canRedo) return;
    setState(() => _strokes.add(_redoStack.removeLast()));
    _scheduleAutosave();
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack
        ..clear()
        ..addAll(_strokes);
      _strokes.clear();
    });
    _scheduleAutosave();
  }

  Future<void> _savePreview() async {
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    if (data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，请再试一次')));
      return;
    }
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    try {
      await widget.onSaved(bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，请检查设备存储空间')));
      return;
    }
    if (!mounted) return;
    final sizeKb = (data.lengthInBytes / 1024).round();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sizeKb > 0 ? '已保存到作品集，约 $sizeKb KB' : '已保存到作品集'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      _orange,
      const Color(0xFFFF9D00),
      const Color(0xFF20B26B),
      const Color(0xFF45A7E8),
      const Color(0xFF8C63E8),
      const Color(0xFF3A1D10),
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
                key: const ValueKey('free-drawing-canvas'),
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
              SizedBox(width: isWide ? 178 : double.infinity, child: tools),
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

Map<String, Object?> _draftFromStrokes(
  List<DrawingStroke> strokes, {
  int? stepIndex,
}) => {
  'version': 1,
  'stepIndex': ?stepIndex,
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
  'strokes': [
    for (final stroke in strokes)
      {
        'tool': stroke.tool.name,
        'color': stroke.color.toARGB32(),
        'width': stroke.baseWidth,
        'points': [
          for (final point in stroke.points)
            [point.offset.dx, point.offset.dy, point.pressure],
        ],
      },
  ],
};

List<DrawingStroke> _strokesFromDraft(Map<String, Object?>? draft) {
  if (draft == null) return [];
  try {
    return [
      for (final item in draft['strokes'] as List<dynamic>)
        DrawingStroke(
          tool: DrawingTool.values.byName(
            (item as Map<String, dynamic>)['tool'] as String,
          ),
          color: Color((item['color'] as num).toInt()),
          baseWidth: (item['width'] as num).toDouble(),
          points: [
            for (final point in item['points'] as List<dynamic>)
              DrawingPoint(
                Offset(
                  (point[0] as num).toDouble(),
                  (point[1] as num).toDouble(),
                ),
                (point[2] as num).toDouble(),
              ),
          ],
        ),
    ];
  } catch (_) {
    return [];
  }
}

Future<Uint8List> _renderDrawingPng(
  List<DrawingStroke> strokes,
  Size size,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(2);
  NativeCanvasPainter(strokes: strokes).paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    math.max(1, (size.width * 2).round()),
    math.max(1, (size.height * 2).round()),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  if (data == null) throw StateError('无法生成作品图片');
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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
  NativeCanvasPainter({required this.strokes, this.guide});

  final List<DrawingStroke> strokes;
  final CustomPainter? guide;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    _drawPaperTexture(canvas, size);
    guide?.paint(canvas, size);

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

enum LessonArt { cat, dinosaur, car, lantern }

class LessonStep {
  const LessonStep(this.title, this.description, this.tip);

  final String title;
  final String description;
  final String tip;
}

class DrawingLesson {
  const DrawingLesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.duration,
    required this.color,
    required this.icon,
    required this.art,
    required this.steps,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String duration;
  final Color color;
  final IconData icon;
  final LessonArt art;
  final List<LessonStep> steps;
}

const _drawingLessons = [
  DrawingLesson(
    id: 'round-cat',
    title: '圆脸小猫',
    subtitle: '用圆形和三角形画一只萌萌的小猫',
    category: '可爱动物',
    duration: '约 6 分钟',
    color: _mint,
    icon: Icons.pets_rounded,
    art: LessonArt.cat,
    steps: [
      LessonStep('画一个大圆', '先画一个大大的圆，做小猫的脑袋。', '慢慢转动手腕，圆不需要特别完美。'),
      LessonStep('添上三角耳朵', '在圆形上方画两个小三角形。', '两只耳朵一高一低也很可爱。'),
      LessonStep('画弯弯的眼睛', '加上眼睛和一个小鼻子。', '像画两个月牙一样画眼睛。'),
      LessonStep('加上笑脸和胡须', '最后画嘴巴和三根长胡须。', '选喜欢的颜色，再加一点腮红吧。'),
    ],
  ),
  DrawingLesson(
    id: 'little-dinosaur',
    title: '快乐小恐龙',
    subtitle: '从椭圆开始，画一只温柔的小恐龙',
    category: '恐龙世界',
    duration: '约 8 分钟',
    color: _peach,
    icon: Icons.park_rounded,
    art: LessonArt.dinosaur,
    steps: [
      LessonStep('画椭圆身体', '横着画一个胖胖的椭圆。', '椭圆越饱满，小恐龙越可爱。'),
      LessonStep('加上脑袋和脖子', '从身体向上画长脖子和小脑袋。', '用一条柔软的弧线连接身体。'),
      LessonStep('添四条腿和尾巴', '画短短的腿，再加一条长尾巴。', '脚掌可以画成圆圆的小方块。'),
      LessonStep('画背刺和表情', '沿背部加三角背刺，再画笑脸。', '背刺可以大小不一样。'),
    ],
  ),
  DrawingLesson(
    id: 'tiny-car',
    title: '出发吧小汽车',
    subtitle: '组合方形和圆形，画自己的小汽车',
    category: '交通工具',
    duration: '约 7 分钟',
    color: _butter,
    icon: Icons.directions_car_rounded,
    art: LessonArt.car,
    steps: [
      LessonStep('画长方形车身', '先画一个圆角长方形。', '车头可以稍微高一点。'),
      LessonStep('加上车顶', '在车身上画一个梯形车顶。', '给车顶留出两扇窗的位置。'),
      LessonStep('画两个轮子', '在车身下方画两个圆形轮子。', '让两个轮子差不多大。'),
      LessonStep('装饰车窗和车灯', '画上车窗、车灯和喜欢的花纹。', '给小汽车取一个名字吧。'),
    ],
  ),
  DrawingLesson(
    id: 'red-lantern',
    title: '圆圆红灯笼',
    subtitle: '用弧线画一个喜气洋洋的小灯笼',
    category: '节日快乐',
    duration: '约 6 分钟',
    color: _rose,
    icon: Icons.celebration_rounded,
    art: LessonArt.lantern,
    steps: [
      LessonStep('画灯笼肚子', '画一个竖着的胖椭圆。', '上下稍窄，中间圆鼓鼓。'),
      LessonStep('加上顶盖和底座', '在椭圆上下各画一个小长方形。', '让顶盖和底座对齐。'),
      LessonStep('画提绳和流苏', '上面添提绳，下面添长流苏。', '流苏可以画得轻轻摆动。'),
      LessonStep('加花纹和光芒', '在灯笼上画弧线，再添几颗小星星。', '最后涂上最喜庆的颜色。'),
    ],
  ),
];

class LessonsPage extends StatefulWidget {
  const LessonsPage({
    super.key,
    required this.onBack,
    required this.progress,
    required this.onProgress,
    required this.onArtworkSaved,
    required this.store,
  });
  final VoidCallback onBack;
  final Map<String, int> progress;
  final void Function(String lessonId, int completedSteps) onProgress;
  final Future<void> Function(DrawingLesson lesson, Uint8List pngBytes)
  onArtworkSaved;
  final ArtistStore store;

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  String _category = '全部';
  DrawingLesson? _activeLesson;

  int _progressFor(DrawingLesson lesson) =>
      math.min(widget.progress[lesson.id] ?? 0, lesson.steps.length);

  void _openLesson(DrawingLesson lesson) =>
      setState(() => _activeLesson = lesson);

  void _updateProgress(DrawingLesson lesson, int completedSteps) {
    widget.onProgress(lesson.id, completedSteps.clamp(0, lesson.steps.length));
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _activeLesson;
    return AppPage(
      title: lesson == null ? '跟着学画' : '跟着学画 · ${lesson.title}',
      onBack: lesson == null
          ? widget.onBack
          : () => setState(() => _activeLesson = null),
      child: lesson == null
          ? LessonCatalog(
              category: _category,
              progress: widget.progress,
              onCategory: (category) => setState(() => _category = category),
              onOpen: _openLesson,
            )
          : GuidedLessonWorkspace(
              key: ValueKey(lesson.id),
              lesson: lesson,
              initialStep: math.min(
                _progressFor(lesson),
                lesson.steps.length - 1,
              ),
              onProgress: (completedSteps) =>
                  _updateProgress(lesson, completedSteps),
              onFinish: () => setState(() => _activeLesson = null),
              onArtworkSaved: (pngBytes) =>
                  widget.onArtworkSaved(lesson, pngBytes),
              store: widget.store,
            ),
    );
  }
}

class LessonCatalog extends StatelessWidget {
  const LessonCatalog({
    super.key,
    required this.category,
    required this.progress,
    required this.onCategory,
    required this.onOpen,
  });

  final String category;
  final Map<String, int> progress;
  final ValueChanged<String> onCategory;
  final ValueChanged<DrawingLesson> onOpen;

  int _progressFor(DrawingLesson lesson) =>
      math.min(progress[lesson.id] ?? 0, lesson.steps.length);

  @override
  Widget build(BuildContext context) {
    const categories = ['全部', '可爱动物', '恐龙世界', '交通工具', '节日快乐'];
    final visibleLessons = category == '全部'
        ? _drawingLessons
        : _drawingLessons
              .where((lesson) => lesson.category == category)
              .toList();
    final completedCount = _drawingLessons
        .where((lesson) => _progressFor(lesson) == lesson.steps.length)
        .length;
    final continueLesson = _drawingLessons.firstWhere(
      (lesson) =>
          _progressFor(lesson) > 0 &&
          _progressFor(lesson) < lesson.steps.length,
      orElse: () => _drawingLessons.first,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 760;
        return ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            LessonWelcomeBanner(
              lesson: continueLesson,
              completedSteps: _progressFor(continueLesson),
              completedLessons: completedCount,
              onTap: () => onOpen(continueLesson),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in categories) ...[
                    ChoiceChip(
                      label: Text(item),
                      selected: category == item,
                      selectedColor: _mint,
                      side: BorderSide.none,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                      onSelected: (_) => onCategory(item),
                    ),
                    const SizedBox(width: 9),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  '挑一幅开始吧',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${visibleLessons.length} 节课',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: twoColumns ? 2 : 1,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: twoColumns ? 170 : 156,
              ),
              itemCount: visibleLessons.length,
              itemBuilder: (context, index) {
                final lesson = visibleLessons[index];
                return LessonCourseCard(
                  lesson: lesson,
                  completedSteps: _progressFor(lesson),
                  onTap: () => onOpen(lesson),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class LessonWelcomeBanner extends StatelessWidget {
  const LessonWelcomeBanner({
    super.key,
    required this.lesson,
    required this.completedSteps,
    required this.completedLessons,
    required this.onTap,
  });

  final DrawingLesson lesson;
  final int completedSteps;
  final int completedLessons;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasProgress = completedSteps > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _brown.withValues(alpha: .12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showPreview = constraints.maxWidth >= 460;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .78),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '已完成 $completedLessons 幅',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '今天也要开心画画',
                          style: TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasProgress ? '继续画「${lesson.title}」' : '从一笔开始，画出大世界',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasProgress
                          ? '已经完成 $completedSteps / ${lesson.steps.length} 步，接着画吧！'
                          : '挑一幅喜欢的作品，我们一步一步来。',
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('lesson-continue'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onTap,
                      icon: Icon(
                        hasProgress
                            ? Icons.play_arrow_rounded
                            : Icons.auto_awesome_rounded,
                      ),
                      label: Text(
                        hasProgress ? '继续第 ${completedSteps + 1} 步' : '开始第一课',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              if (showPreview) ...[
                const SizedBox(width: 14),
                Container(
                  width: 158,
                  height: 128,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: CustomPaint(
                    painter: LessonGuidePainter(
                      art: lesson.art,
                      visibleSteps: lesson.steps.length,
                      accent: lesson.color,
                      preview: true,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class LessonCourseCard extends StatelessWidget {
  const LessonCourseCard({
    super.key,
    required this.lesson,
    required this.completedSteps,
    required this.onTap,
  });

  final DrawingLesson lesson;
  final int completedSteps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = completedSteps / lesson.steps.length;
    final status = completedSteps == 0
        ? '未开始'
        : completedSteps == lesson.steps.length
        ? '已完成'
        : '$completedSteps / ${lesson.steps.length} 步';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        key: ValueKey('lesson-card-${lesson.id}'),
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 126,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: lesson.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomPaint(
                  painter: LessonGuidePainter(
                    art: lesson.art,
                    visibleSteps: lesson.steps.length,
                    accent: lesson.color,
                    preview: true,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: _orange,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 15,
                          color: _brown,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '入门',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: _brown,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lesson.duration,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _muted,
                            ),
                          ),
                        ),
                        Text(
                          status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: _orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF3E9DC),
                        color: _orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuidedLessonWorkspace extends StatefulWidget {
  const GuidedLessonWorkspace({
    super.key,
    required this.lesson,
    required this.initialStep,
    required this.onProgress,
    required this.onFinish,
    required this.onArtworkSaved,
    required this.store,
  });

  final DrawingLesson lesson;
  final int initialStep;
  final ValueChanged<int> onProgress;
  final VoidCallback onFinish;
  final Future<void> Function(Uint8List pngBytes) onArtworkSaved;
  final ArtistStore store;

  @override
  State<GuidedLessonWorkspace> createState() => _GuidedLessonWorkspaceState();
}

class _GuidedLessonWorkspaceState extends State<GuidedLessonWorkspace> {
  final _canvasKey = GlobalKey();
  final _strokes = <DrawingStroke>[];
  final _redoStack = <DrawingStroke>[];
  DrawingStroke? _activeStroke;
  int? _activePointer;
  late int _stepIndex;
  DrawingTool _tool = DrawingTool.crayon;
  Color _color = _orange;
  double _width = 10;
  bool _showGuide = true;
  Timer? _autosaveTimer;
  bool _isCompleting = false;
  bool _suppressDraftSave = false;

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _stepIndex = widget.initialStep;
    _restoreDraft();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    if (_strokes.isNotEmpty && !_suppressDraftSave) {
      _ignoreStorageError(_persistDraft());
    }
    super.dispose();
  }

  String get _draftKey => 'lesson-${widget.lesson.id}';

  Future<void> _restoreDraft() async {
    final draft = await widget.store.loadDraft(_draftKey);
    if (!mounted || draft == null) return;
    final strokes = _strokesFromDraft(draft);
    final savedStep = (draft['stepIndex'] as num?)?.toInt();
    setState(() {
      _strokes
        ..clear()
        ..addAll(strokes);
      if (savedStep != null) {
        _stepIndex = savedStep.clamp(0, widget.lesson.steps.length - 1);
      }
    });
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 700), _persistDraft);
  }

  Future<void> _persistDraft() async {
    try {
      if (_strokes.isEmpty && _stepIndex == 0) {
        await widget.store.deleteDraft(_draftKey);
        return;
      }
      await widget.store.saveDraft(
        _draftKey,
        _draftFromStrokes(_strokes, stepIndex: _stepIndex),
      );
    } catch (_) {
      // A failed autosave must never interrupt the lesson.
    }
  }

  double _pressure(PointerEvent event) {
    if (event.kind != ui.PointerDeviceKind.stylus &&
        event.kind != ui.PointerDeviceKind.invertedStylus) {
      return 1;
    }
    if (event.pressureMax <= event.pressureMin) return 1;
    return ((event.pressure - event.pressureMin) /
            (event.pressureMax - event.pressureMin))
        .clamp(.35, 1.4);
  }

  void _startStroke(PointerDownEvent event) {
    if (_activePointer != null) return;
    final stroke = DrawingStroke(
      tool: _tool,
      color: _tool == DrawingTool.eraser ? Colors.white : _color,
      baseWidth: _tool == DrawingTool.eraser ? _width * 2.4 : _width,
      points: [DrawingPoint(event.localPosition, _pressure(event))],
    );
    setState(() {
      _activePointer = event.pointer;
      _activeStroke = stroke;
      _redoStack.clear();
      _strokes.add(stroke);
    });
  }

  void _extendStroke(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    setState(
      () => _activeStroke?.points.add(
        DrawingPoint(event.localPosition, _pressure(event)),
      ),
    );
  }

  void _endStroke(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _activeStroke = null;
    _scheduleAutosave();
  }

  void _undo() {
    if (!_canUndo) return;
    setState(() => _redoStack.add(_strokes.removeLast()));
    _scheduleAutosave();
  }

  void _redo() {
    if (!_canRedo) return;
    setState(() => _strokes.add(_redoStack.removeLast()));
    _scheduleAutosave();
  }

  Future<void> _confirmClear() async {
    if (_strokes.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空这张画吗？'),
        content: const Text('清空后还可以用“撤销”找回来。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续画'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _redoStack
        ..clear()
        ..addAll(_strokes);
      _strokes.clear();
    });
    _scheduleAutosave();
  }

  void _previousStep() {
    if (_stepIndex == 0) return;
    setState(() => _stepIndex--);
    _scheduleAutosave();
  }

  void _nextStep() {
    if (_stepIndex < widget.lesson.steps.length - 1) {
      widget.onProgress(_stepIndex + 1);
      setState(() => _stepIndex++);
      _scheduleAutosave();
      return;
    }
    widget.onProgress(widget.lesson.steps.length);
    _completeLesson();
  }

  Future<void> _completeLesson() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    var saved = false;
    try {
      final renderObject = _canvasKey.currentContext?.findRenderObject();
      final size = renderObject is RenderBox && renderObject.hasSize
          ? renderObject.size
          : const Size(720, 520);
      final pngBytes = await _renderDrawingPng(_strokes, size);
      await widget.onArtworkSaved(pngBytes);
      await widget.store.deleteDraft(_draftKey);
      _suppressDraftSave = true;
      saved = true;
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() => _isCompleting = false);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.auto_awesome_rounded, color: _orange, size: 48),
        title: const Text('画好啦！'),
        content: Text(
          saved ? '每一笔都很特别，作品已经自动保存到作品集啦！' : '课程已经完成，但作品保存失败，请检查设备存储空间。',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'restart'),
            child: const Text('再画一次'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'catalog'),
            child: const Text('返回课程'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'restart') {
      setState(() {
        _stepIndex = 0;
        _strokes.clear();
        _redoStack.clear();
        _suppressDraftSave = false;
      });
      widget.onProgress(0);
      _ignoreStorageError(widget.store.deleteDraft(_draftKey));
    } else if (result == 'catalog') {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth >= 760 && constraints.maxHeight >= 520;
        final canvas = _buildCanvas();
        final steps = _buildStepPanel();
        if (sideBySide) {
          return Row(
            children: [
              Expanded(child: canvas),
              const SizedBox(width: 16),
              SizedBox(width: 300, child: steps),
            ],
          );
        }
        return ListView(
          children: [
            SizedBox(
              height: math.max(330, constraints.maxHeight * .72),
              child: canvas,
            ),
            const SizedBox(height: 14),
            SizedBox(height: 430, child: steps),
          ],
        );
      },
    );
  }

  Widget _buildCanvas() {
    final colors = [
      (_orange, '橙色'),
      (const Color(0xFFFFA600), '黄色'),
      (const Color(0xFF20B26B), '绿色'),
      (const Color(0xFF45A7E8), '蓝色'),
      (const Color(0xFF8C63E8), '紫色'),
      (_ink, '深棕色'),
    ];
    return Column(
      children: [
        Expanded(
          child: RepaintBoundary(
            key: _canvasKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Listener(
                    key: const ValueKey('lesson-guided-canvas'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _startStroke,
                    onPointerMove: _extendStroke,
                    onPointerUp: _endStroke,
                    onPointerCancel: _endStroke,
                    child: CustomPaint(
                      painter: NativeCanvasPainter(
                        strokes: _strokes,
                        guide: _showGuide
                            ? LessonGuidePainter(
                                art: widget.lesson.art,
                                visibleSteps: _stepIndex + 1,
                                accent: widget.lesson.color,
                              )
                            : null,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: _brown,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            '显示提示',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                          Switch(
                            value: _showGuide,
                            activeTrackColor: _mint,
                            activeThumbColor: const Color(0xFF07523E),
                            onChanged: (value) =>
                                setState(() => _showGuide = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 62,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ToolChip(
                  icon: Icons.edit_rounded,
                  selected: _tool == DrawingTool.crayon,
                  onTap: () => setState(() => _tool = DrawingTool.crayon),
                  tooltip: '蜡笔',
                ),
                const SizedBox(width: 5),
                ToolChip(
                  icon: Icons.cleaning_services_rounded,
                  selected: _tool == DrawingTool.eraser,
                  onTap: () => setState(() => _tool = DrawingTool.eraser),
                  tooltip: '橡皮',
                ),
                const SizedBox(width: 5),
                ToolChip(
                  icon: Icons.undo_rounded,
                  selected: false,
                  onTap: _canUndo ? _undo : null,
                  tooltip: '撤销',
                ),
                const SizedBox(width: 5),
                ToolChip(
                  icon: Icons.redo_rounded,
                  selected: false,
                  onTap: _canRedo ? _redo : null,
                  tooltip: '重做',
                ),
                const SizedBox(width: 10),
                for (final item in colors) ...[
                  Tooltip(
                    message: item.$2,
                    child: Semantics(
                      button: true,
                      selected:
                          _color == item.$1 && _tool != DrawingTool.eraser,
                      label: '选择${item.$2}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () => setState(() {
                          _color = item.$1;
                          _tool = DrawingTool.crayon;
                        }),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: item.$1,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  _color == item.$1 &&
                                      _tool != DrawingTool.eraser
                                  ? _ink
                                  : Colors.white,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                SizedBox(
                  width: 120,
                  child: Slider(
                    value: _width,
                    min: 4,
                    max: 24,
                    divisions: 10,
                    activeColor: _color,
                    onChanged: (value) => setState(() => _width = value),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '清空画布',
                  onPressed: _strokes.isEmpty ? null : _confirmClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepPanel() {
    final step = widget.lesson.steps[_stepIndex];
    final isLast = _stepIndex == widget.lesson.steps.length - 1;
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.lesson.color,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '第 ${_stepIndex + 1} / ${widget.lesson.steps.length} 步',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                widget.lesson.duration,
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (_stepIndex + 1) / widget.lesson.steps.length,
              minHeight: 7,
              backgroundColor: const Color(0xFFF3E9DC),
              color: _orange,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 145,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.lesson.color.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: CustomPaint(
                      painter: LessonGuidePainter(
                        art: widget.lesson.art,
                        visibleSteps: _stepIndex + 1,
                        accent: widget.lesson.color,
                        preview: true,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          color: Color(0xFFE49A00),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.tip,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                key: const ValueKey('lesson-previous-step'),
                onPressed: _stepIndex == 0 ? null : _previousStep,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('上一步'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('lesson-next-step'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isCompleting ? null : _nextStep,
                  icon: _isCompleting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isLast
                              ? Icons.celebration_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    _isCompleting ? '正在保存…' : (isLast ? '完成课程' : '下一步'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LessonGuidePainter extends CustomPainter {
  LessonGuidePainter({
    required this.art,
    required this.visibleSteps,
    required this.accent,
    this.preview = false,
  });

  final LessonArt art;
  final int visibleSteps;
  final Color accent;
  final bool preview;

  Paint _linePaint(int stage, double scale) {
    final isCurrent = stage == visibleSteps - 1;
    return Paint()
      ..color = preview
          ? _ink.withValues(alpha: .78)
          : (isCurrent
                ? _orange.withValues(alpha: .58)
                : _brown.withValues(alpha: .24))
      ..strokeWidth = (preview ? 4 : 5) * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  }

  Paint _dotPaint(int stage) => Paint()
    ..color = preview
        ? _ink.withValues(alpha: .82)
        : (stage == visibleSteps - 1
              ? _orange.withValues(alpha: .62)
              : _brown.withValues(alpha: .28));

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    final scale = unit / 300;
    final center = Offset(size.width / 2, size.height / 2 + 7 * scale);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    switch (art) {
      case LessonArt.cat:
        _paintCat(canvas, scale);
      case LessonArt.dinosaur:
        _paintDinosaur(canvas, scale);
      case LessonArt.car:
        _paintCar(canvas, scale);
      case LessonArt.lantern:
        _paintLantern(canvas, scale);
    }
    canvas.restore();
  }

  void _paintCat(Canvas canvas, double s) {
    if (visibleSteps >= 1) {
      canvas.drawCircle(Offset(0, 4 * s), 72 * s, _linePaint(0, s));
    }
    if (visibleSteps >= 2) {
      final leftEar = Path()
        ..moveTo(-58 * s, -39 * s)
        ..lineTo(-47 * s, -102 * s)
        ..lineTo(-12 * s, -62 * s);
      final rightEar = Path()
        ..moveTo(58 * s, -39 * s)
        ..lineTo(47 * s, -102 * s)
        ..lineTo(12 * s, -62 * s);
      canvas.drawPath(leftEar, _linePaint(1, s));
      canvas.drawPath(rightEar, _linePaint(1, s));
    }
    if (visibleSteps >= 3) {
      final paint = _linePaint(2, s);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(-27 * s, -3 * s),
          width: 25 * s,
          height: 18 * s,
        ),
        .12,
        math.pi * .78,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(27 * s, -3 * s),
          width: 25 * s,
          height: 18 * s,
        ),
        .12,
        math.pi * .78,
        false,
        paint,
      );
      canvas.drawCircle(Offset(0, 18 * s), 5 * s, _dotPaint(2));
    }
    if (visibleSteps >= 4) {
      final paint = _linePaint(3, s);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(-8 * s, 28 * s),
          width: 18 * s,
          height: 14 * s,
        ),
        0,
        math.pi,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(8 * s, 28 * s),
          width: 18 * s,
          height: 14 * s,
        ),
        0,
        math.pi,
        false,
        paint,
      );
      for (final y in [19.0, 31.0, 43.0]) {
        canvas.drawLine(
          Offset(-18 * s, y * s),
          Offset(-84 * s, (y - 8) * s),
          paint,
        );
        canvas.drawLine(
          Offset(18 * s, y * s),
          Offset(84 * s, (y - 8) * s),
          paint,
        );
      }
    }
  }

  void _paintDinosaur(Canvas canvas, double s) {
    if (visibleSteps >= 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-15 * s, 18 * s),
          width: 142 * s,
          height: 92 * s,
        ),
        _linePaint(0, s),
      );
    }
    if (visibleSteps >= 2) {
      final neck = Path()
        ..moveTo(36 * s, -5 * s)
        ..quadraticBezierTo(63 * s, -29 * s, 63 * s, -66 * s);
      canvas.drawPath(neck, _linePaint(1, s));
      canvas.drawCircle(Offset(68 * s, -77 * s), 31 * s, _linePaint(1, s));
    }
    if (visibleSteps >= 3) {
      final paint = _linePaint(2, s);
      canvas.drawLine(Offset(-58 * s, 48 * s), Offset(-64 * s, 91 * s), paint);
      canvas.drawLine(Offset(5 * s, 57 * s), Offset(10 * s, 91 * s), paint);
      final tail = Path()
        ..moveTo(-82 * s, 4 * s)
        ..quadraticBezierTo(-122 * s, -3 * s, -130 * s, -38 * s);
      canvas.drawPath(tail, paint);
    }
    if (visibleSteps >= 4) {
      final paint = _linePaint(3, s);
      for (var i = 0; i < 4; i++) {
        final x = (-58 + i * 30) * s;
        final spike = Path()
          ..moveTo(x, -25 * s)
          ..lineTo(x + 13 * s, -54 * s)
          ..lineTo(x + 24 * s, -24 * s);
        canvas.drawPath(spike, paint);
      }
      canvas.drawCircle(Offset(78 * s, -83 * s), 4 * s, _dotPaint(3));
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(76 * s, -66 * s),
          width: 22 * s,
          height: 13 * s,
        ),
        0,
        math.pi,
        false,
        paint,
      );
    }
  }

  void _paintCar(Canvas canvas, double s) {
    if (visibleSteps >= 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, 18 * s),
            width: 188 * s,
            height: 66 * s,
          ),
          Radius.circular(17 * s),
        ),
        _linePaint(0, s),
      );
    }
    if (visibleSteps >= 2) {
      final roof = Path()
        ..moveTo(-58 * s, -15 * s)
        ..lineTo(-30 * s, -61 * s)
        ..lineTo(43 * s, -61 * s)
        ..lineTo(72 * s, -15 * s);
      canvas.drawPath(roof, _linePaint(1, s));
    }
    if (visibleSteps >= 3) {
      final paint = _linePaint(2, s);
      canvas.drawCircle(Offset(-56 * s, 55 * s), 24 * s, paint);
      canvas.drawCircle(Offset(57 * s, 55 * s), 24 * s, paint);
      canvas.drawCircle(Offset(-56 * s, 55 * s), 7 * s, _dotPaint(2));
      canvas.drawCircle(Offset(57 * s, 55 * s), 7 * s, _dotPaint(2));
    }
    if (visibleSteps >= 4) {
      final paint = _linePaint(3, s);
      canvas.drawLine(Offset(3 * s, -57 * s), Offset(3 * s, -16 * s), paint);
      canvas.drawLine(
        Offset(-28 * s, -55 * s),
        Offset(-49 * s, -17 * s),
        paint,
      );
      canvas.drawCircle(Offset(80 * s, 15 * s), 8 * s, _dotPaint(3));
      canvas.drawLine(Offset(-88 * s, 12 * s), Offset(-70 * s, 12 * s), paint);
    }
  }

  void _paintLantern(Canvas canvas, double s) {
    if (visibleSteps >= 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -8 * s),
          width: 126 * s,
          height: 150 * s,
        ),
        _linePaint(0, s),
      );
    }
    if (visibleSteps >= 2) {
      final paint = _linePaint(1, s);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -87 * s),
            width: 72 * s,
            height: 18 * s,
          ),
          Radius.circular(5 * s),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, 71 * s),
            width: 72 * s,
            height: 18 * s,
          ),
          Radius.circular(5 * s),
        ),
        paint,
      );
    }
    if (visibleSteps >= 3) {
      final paint = _linePaint(2, s);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(0, -106 * s),
          width: 70 * s,
          height: 58 * s,
        ),
        math.pi,
        math.pi,
        false,
        paint,
      );
      canvas.drawLine(Offset(0, 81 * s), Offset(0, 123 * s), paint);
      for (final x in [-18.0, 0.0, 18.0]) {
        canvas.drawLine(Offset(x * s, 123 * s), Offset(x * s, 148 * s), paint);
      }
    }
    if (visibleSteps >= 4) {
      final paint = _linePaint(3, s);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(0, -8 * s),
          width: 72 * s,
          height: 148 * s,
        ),
        -math.pi / 2,
        math.pi,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(0, -8 * s),
          width: 72 * s,
          height: 148 * s,
        ),
        math.pi / 2,
        math.pi,
        false,
        paint,
      );
      for (final offset in [
        const Offset(-90, -58),
        const Offset(92, -30),
        const Offset(-86, 36),
      ]) {
        canvas.drawCircle(offset * s, 5 * s, _dotPaint(3));
      }
    }
  }

  @override
  bool shouldRepaint(covariant LessonGuidePainter oldDelegate) {
    return oldDelegate.art != art ||
        oldDelegate.visibleSteps != visibleSteps ||
        oldDelegate.accent != accent ||
        oldDelegate.preview != preview;
  }
}

enum GalleryFilter { all, recent, favorite }

class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
    required this.artworks,
    required this.onBack,
    required this.onCreateNew,
    required this.onToggleFavorite,
    required this.onRename,
    required this.onDelete,
  });

  final List<GalleryArtwork> artworks;
  final VoidCallback onBack;
  final VoidCallback onCreateNew;
  final ValueChanged<String> onToggleFavorite;
  final void Function(String id, String title) onRename;
  final ValueChanged<String> onDelete;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  GalleryFilter _filter = GalleryFilter.all;
  String? _selectedArtworkId;

  GalleryArtwork? get _selectedArtwork {
    for (final artwork in widget.artworks) {
      if (artwork.id == _selectedArtworkId) return artwork;
    }
    return null;
  }

  List<GalleryArtwork> get _visibleArtworks {
    return switch (_filter) {
      GalleryFilter.all => widget.artworks,
      GalleryFilter.recent =>
        widget.artworks
            .where((artwork) => artwork.createdLabel != '上周')
            .toList(),
      GalleryFilter.favorite =>
        widget.artworks.where((artwork) => artwork.isFavorite).toList(),
    };
  }

  Future<void> _rename(GalleryArtwork artwork) async {
    var draftTitle = artwork.title;
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('给作品换个名字'),
        content: TextFormField(
          key: const ValueKey('gallery-rename-field'),
          initialValue: artwork.title,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            labelText: '作品名称',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => draftTitle = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, draftTitle),
            child: const Text('保存名字'),
          ),
        ],
      ),
    );
    final trimmed = title?.trim();
    if (trimmed == null || trimmed.isEmpty || !mounted) return;
    widget.onRename(artwork.id, trimmed);
  }

  Future<void> _delete(GalleryArtwork artwork) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这幅作品吗？'),
        content: Text('「${artwork.title}」删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留作品'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB33A2B),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _selectedArtworkId = null);
    widget.onDelete(artwork.id);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedArtwork;
    return AppPage(
      title: selected == null ? '我的作品集' : '作品详情 · ${selected.title}',
      onBack: selected == null
          ? widget.onBack
          : () => setState(() => _selectedArtworkId = null),
      child: selected == null
          ? GalleryOverview(
              artworks: _visibleArtworks,
              totalCount: widget.artworks.length,
              favoriteCount: widget.artworks
                  .where((artwork) => artwork.isFavorite)
                  .length,
              createdCount: widget.artworks
                  .where((artwork) => artwork.isUserCreated)
                  .length,
              filter: _filter,
              onFilter: (filter) => setState(() => _filter = filter),
              onOpen: (artwork) =>
                  setState(() => _selectedArtworkId = artwork.id),
              onCreateNew: widget.onCreateNew,
              onToggleFavorite: widget.onToggleFavorite,
            )
          : GalleryArtworkDetail(
              artwork: selected,
              onFavorite: () => widget.onToggleFavorite(selected.id),
              onCreateNew: widget.onCreateNew,
              onRename: selected.isUserCreated ? () => _rename(selected) : null,
              onDelete: selected.isUserCreated ? () => _delete(selected) : null,
            ),
    );
  }
}

class GalleryOverview extends StatelessWidget {
  const GalleryOverview({
    super.key,
    required this.artworks,
    required this.totalCount,
    required this.favoriteCount,
    required this.createdCount,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
    required this.onCreateNew,
    required this.onToggleFavorite,
  });

  final List<GalleryArtwork> artworks;
  final int totalCount;
  final int favoriteCount;
  final int createdCount;
  final GalleryFilter filter;
  final ValueChanged<GalleryFilter> onFilter;
  final ValueChanged<GalleryArtwork> onOpen;
  final VoidCallback onCreateNew;
  final ValueChanged<String> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = constraints.maxWidth >= 760 ? 250.0 : 230.0;
        return ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            GalleryHero(
              artworks: artworks.isEmpty ? const [] : artworks.take(3).toList(),
              totalCount: totalCount,
              favoriteCount: favoriteCount,
              createdCount: createdCount,
              onCreateNew: onCreateNew,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GalleryFilterChip(
                          label: '全部',
                          filter: GalleryFilter.all,
                          selected: filter == GalleryFilter.all,
                          onTap: onFilter,
                        ),
                        const SizedBox(width: 9),
                        GalleryFilterChip(
                          label: '最近',
                          filter: GalleryFilter.recent,
                          selected: filter == GalleryFilter.recent,
                          onTap: onFilter,
                        ),
                        const SizedBox(width: 9),
                        GalleryFilterChip(
                          label: '收藏',
                          filter: GalleryFilter.favorite,
                          selected: filter == GalleryFilter.favorite,
                          onTap: onFilter,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${artworks.length} 幅作品',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (artworks.isEmpty)
              GalleryEmptyState(
                isFavorite: filter == GalleryFilter.favorite,
                onCreateNew: onCreateNew,
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxExtent,
                  mainAxisExtent: 250,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: artworks.length,
                itemBuilder: (context, index) {
                  final artwork = artworks[index];
                  return GalleryArtworkCard(
                    artwork: artwork,
                    onTap: () => onOpen(artwork),
                    onFavorite: () => onToggleFavorite(artwork.id),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class GalleryFilterChip extends StatelessWidget {
  const GalleryFilterChip({
    super.key,
    required this.label,
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final GalleryFilter filter;
  final bool selected;
  final ValueChanged<GalleryFilter> onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: ValueKey('gallery-filter-$label'),
      label: Text(label),
      avatar: Icon(
        filter == GalleryFilter.favorite
            ? Icons.favorite_rounded
            : filter == GalleryFilter.recent
            ? Icons.schedule_rounded
            : Icons.grid_view_rounded,
        size: 18,
      ),
      selected: selected,
      selectedColor: _butter,
      side: BorderSide.none,
      labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
      onSelected: (_) => onTap(filter),
    );
  }
}

class GalleryHero extends StatelessWidget {
  const GalleryHero({
    super.key,
    required this.artworks,
    required this.totalCount,
    required this.favoriteCount,
    required this.createdCount,
    required this.onCreateNew,
  });

  final List<GalleryArtwork> artworks;
  final int totalCount;
  final int favoriteCount;
  final int createdCount;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
      decoration: BoxDecoration(
        color: _butter,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _brown.withValues(alpha: .12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showPreview =
              constraints.maxWidth >= 560 && artworks.isNotEmpty;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '米娅的小画展',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '每一幅画，都是独一无二的小故事。',
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        GalleryStat(
                          icon: Icons.photo_library_rounded,
                          text: '$totalCount 幅作品',
                        ),
                        GalleryStat(
                          icon: Icons.favorite_rounded,
                          text: '$favoriteCount 个收藏',
                        ),
                        GalleryStat(
                          icon: Icons.brush_rounded,
                          text: '$createdCount 幅新画',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('gallery-create-new'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onCreateNew,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        '画一幅新的',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              if (showPreview) ...[
                const SizedBox(width: 18),
                SizedBox(
                  width: 230,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < artworks.length; i++)
                        Transform.translate(
                          offset: Offset((i - 1) * 44, i.isEven ? -3 : 5),
                          child: Transform.rotate(
                            angle: (i - 1) * .08,
                            child: Container(
                              width: 108,
                              height: 116,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ArtworkThumbnail(artwork: artworks[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class GalleryStat extends StatelessWidget {
  const GalleryStat({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _brown, size: 16),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryArtworkCard extends StatelessWidget {
  const GalleryArtworkCard({
    super.key,
    required this.artwork,
    required this.onTap,
    required this.onFavorite,
  });

  final GalleryArtwork artwork;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        key: ValueKey('gallery-card-${artwork.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: ArtworkThumbnail(artwork: artwork)),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: IconButton.filled(
                        key: ValueKey('gallery-favorite-${artwork.id}'),
                        tooltip: artwork.isFavorite ? '取消收藏' : '收藏作品',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .92),
                          foregroundColor: artwork.isFavorite
                              ? _orange
                              : _brown,
                        ),
                        onPressed: onFavorite,
                        icon: Icon(
                          artwork.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                artwork.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    artwork.isUserCreated
                        ? Icons.brush_rounded
                        : Icons.auto_awesome_rounded,
                    size: 14,
                    color: _muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      artwork.isUserCreated
                          ? '${artwork.source == 'lesson' ? '课程作品' : '自由创作'} · ${artwork.createdLabel}'
                          : '示例作品 · ${artwork.createdLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _orange,
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

class ArtworkThumbnail extends StatelessWidget {
  const ArtworkThumbnail({super.key, required this.artwork});

  final GalleryArtwork artwork;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: artwork.color,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: artwork.pngBytes != null
              ? Image.memory(
                  artwork.pngBytes!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                )
              : CustomPaint(
                  painter: SketchPainter(artwork.kind ?? SketchKind.sun),
                  child: const SizedBox.expand(),
                ),
        ),
      ),
    );
  }
}

class GalleryArtworkDetail extends StatelessWidget {
  const GalleryArtworkDetail({
    super.key,
    required this.artwork,
    required this.onFavorite,
    required this.onCreateNew,
    this.onRename,
    this.onDelete,
  });

  final GalleryArtwork artwork;
  final VoidCallback onFavorite;
  final VoidCallback onCreateNew;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth >= 720 && constraints.maxHeight >= 500;
        final preview = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: ArtworkThumbnail(artwork: artwork),
        );
        final details = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: artwork.color,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      artwork.isUserCreated ? '我的创作' : '画室示例',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: ValueKey('gallery-detail-favorite-${artwork.id}'),
                    tooltip: artwork.isFavorite ? '取消收藏' : '收藏作品',
                    onPressed: onFavorite,
                    icon: Icon(
                      artwork.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: artwork.isFavorite ? _orange : _brown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                artwork.title,
                style: const TextStyle(
                  fontSize: 29,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${artwork.createdLabel}完成',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '每一次创作都值得被好好收藏。给喜欢的作品点一颗爱心吧！',
                        style: TextStyle(
                          height: 1.4,
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '作品信息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              GalleryInfoRow(
                icon: Icons.schedule_rounded,
                label: '完成时间',
                value: artwork.createdLabel,
              ),
              const SizedBox(height: 8),
              GalleryInfoRow(
                icon: Icons.palette_rounded,
                label: '创作工具',
                value: artwork.isUserCreated ? '自由画板' : '画室示例',
              ),
              const SizedBox(height: 8),
              const GalleryInfoRow(
                icon: Icons.crop_landscape_rounded,
                label: '画布形式',
                value: '横屏画布',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onCreateNew,
                  icon: const Icon(Icons.brush_rounded),
                  label: const Text(
                    '再画一幅',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              if (onRename != null || onDelete != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onRename != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('gallery-rename'),
                          onPressed: onRename,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('重命名'),
                        ),
                      ),
                    if (onRename != null && onDelete != null)
                      const SizedBox(width: 10),
                    if (onDelete != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('gallery-delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB33A2B),
                          ),
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('删除'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );

        if (sideBySide) {
          return Row(
            children: [
              Expanded(child: preview),
              const SizedBox(width: 16),
              SizedBox(width: 330, child: details),
            ],
          );
        }
        return ListView(
          children: [
            SizedBox(height: 340, child: preview),
            const SizedBox(height: 14),
            SizedBox(height: artwork.isUserCreated ? 400 : 340, child: details),
          ],
        );
      },
    );
  }
}

class GalleryInfoRow extends StatelessWidget {
  const GalleryInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _brown),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: _ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class GalleryEmptyState extends StatelessWidget {
  const GalleryEmptyState({
    super.key,
    required this.isFavorite,
    required this.onCreateNew,
  });

  final bool isFavorite;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFavorite
                ? Icons.favorite_border_rounded
                : Icons.photo_library_outlined,
            size: 52,
            color: _brown,
          ),
          const SizedBox(height: 12),
          Text(
            isFavorite ? '还没有收藏作品' : '作品集还是空的',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFavorite ? '看到喜欢的作品，就点亮右上角的爱心。' : '去画板完成第一幅作品吧！',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (!isFavorite)
            FilledButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.brush_rounded),
              label: const Text('开始画画'),
            ),
        ],
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 112)),
              ),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 50, color: _brown),
              SizedBox(height: 18),
              Text(
                'Parents Only',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
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
                key: const ValueKey('app-page-back'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
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
