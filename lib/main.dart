import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lovable_little_artist/local_artist_store.dart';
import 'package:lovable_little_artist/studio_audio.dart';

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

enum StudioTab { home, draw, coloring, lessons, gallery, animation, parent }

class StudioHome extends StatefulWidget {
  const StudioHome({super.key, required this.store});

  final ArtistStore store;

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> with WidgetsBindingObserver {
  StudioTab tab = StudioTab.home;
  int _nextArtworkNumber = 1;
  final Map<String, int> _lessonProgress = {};
  final Map<String, Object?> _preferences = {};
  final StudioAudio _audio = StudioAudio();
  DateTime _activeSince = DateTime.now();
  Timer? _usageTicker;
  int _storedUsageSeconds = 0;
  int _streak = 0;
  int _creationStars = 0;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  String _ageGroup = '4-6岁';
  String _difficulty = '入门';
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
    WidgetsBinding.instance.addObserver(this);
    _usageTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && tab == StudioTab.parent) setState(() {});
    });
    _restoreLocalState();
  }

  @override
  void dispose() {
    _usageTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _storeElapsedUsage();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _storeElapsedUsage();
    } else if (state == AppLifecycleState.resumed) {
      _activeSince = DateTime.now();
    }
  }

  Future<void> _restoreLocalState() async {
    final snapshot = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _nextArtworkNumber = snapshot.nextArtworkNumber;
      _lessonProgress
        ..clear()
        ..addAll(snapshot.lessonProgress);
      _preferences
        ..clear()
        ..addAll(snapshot.preferences);
      _storedUsageSeconds =
          (_preferences['usageSeconds'] as num?)?.toInt() ?? 0;
      _streak = (_preferences['creationStreak'] as num?)?.toInt() ?? 0;
      _creationStars = (_preferences['creationStars'] as num?)?.toInt() ?? 0;
      _soundEnabled = _preferences['soundEnabled'] as bool? ?? true;
      _musicEnabled = _preferences['musicEnabled'] as bool? ?? true;
      _ageGroup = _preferences['ageGroup'] as String? ?? '4-6岁';
      _difficulty = _preferences['difficulty'] as String? ?? '入门';
      artworks.insertAll(0, snapshot.artworks.map(_galleryArtworkFromStored));
    });
    if (_preferences['onboardingComplete'] != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showOnboarding());
      });
    }
    await _audio.initialize(sound: _soundEnabled, music: _musicEnabled);
  }

  int get _usageSeconds =>
      _storedUsageSeconds + DateTime.now().difference(_activeSince).inSeconds;

  void _storeElapsedUsage() {
    final elapsed = DateTime.now().difference(_activeSince).inSeconds;
    if (elapsed <= 0) return;
    _storedUsageSeconds += elapsed;
    _activeSince = DateTime.now();
    _preferences['usageSeconds'] = _storedUsageSeconds;
    _ignoreStorageError(widget.store.savePreferences(_preferences));
  }

  void _savePreference(String key, Object? value) {
    setState(() {
      if (value == null) {
        _preferences.remove(key);
      } else {
        _preferences[key] = value;
      }
    });
    _ignoreStorageError(widget.store.savePreferences(_preferences));
  }

  Future<void> _showOnboarding() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LittleArtistOnboarding(),
    );
    _preferences['onboardingComplete'] = true;
    _ignoreStorageError(widget.store.savePreferences(_preferences));
  }

  void _recordCreation(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final lastText = _preferences['lastCreationDate'] as String?;
    final last = lastText == null ? null : DateTime.tryParse(lastText);
    setState(() {
      if (last == null) {
        _streak = 1;
      } else {
        final lastDay = DateTime(last.year, last.month, last.day);
        final days = today.difference(lastDay).inDays;
        if (days == 1) _streak++;
        if (days > 1) _streak = 1;
      }
      _preferences['creationStreak'] = _streak;
      _creationStars++;
      _preferences['creationStars'] = _creationStars;
      _preferences['lastCreationDate'] = today.toIso8601String();
    });
    _ignoreStorageError(widget.store.savePreferences(_preferences));
  }

  Future<void> _addArtwork(
    Uint8List pngBytes,
    Map<String, Object?> replayData,
  ) async {
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
      replayData: replayData,
    );
    await widget.store.saveArtwork(_storedArtworkFromGallery(artwork));
    if (!mounted) return;
    setState(() {
      _nextArtworkNumber++;
      artworks.insert(0, artwork);
    });
    _recordCreation(now);
  }

  Future<void> _addColoringArtwork(
    String templateTitle,
    Uint8List pngBytes,
  ) async {
    final now = DateTime.now();
    final id = 'coloring-${now.microsecondsSinceEpoch}';
    final artwork = GalleryArtwork(
      id: id,
      title: '涂色作品 · $templateTitle',
      createdLabel: '刚刚',
      createdAt: now,
      color: _butter,
      pngBytes: pngBytes,
      isUserCreated: true,
      source: 'coloring',
    );
    await widget.store.saveArtwork(_storedArtworkFromGallery(artwork));
    if (!mounted) return;
    setState(() {
      _nextArtworkNumber++;
      artworks.insert(0, artwork);
    });
    _recordCreation(now);
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
    _recordCreation(now);
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
        replayData: stored.replayData,
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
        replayData: artwork.replayData,
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
            artworks: artworks,
            streak: _streak,
            creationStars: _creationStars,
            onOpen: (next) => setState(() => tab = next),
          ),
          StudioTab.draw => DrawPage(
            onBack: () => setState(() => tab = StudioTab.home),
            onSaved: _addArtwork,
            store: widget.store,
          ),
          StudioTab.coloring => ColoringPage(
            onBack: () => setState(() => tab = StudioTab.home),
            onSaved: _addColoringArtwork,
          ),
          StudioTab.lessons => LessonsPage(
            onBack: () => setState(() => tab = StudioTab.home),
            progress: _lessonProgress,
            onProgress: _updateLessonProgress,
            onArtworkSaved: _addLessonArtwork,
            store: widget.store,
            audio: _audio,
            soundEnabled: _soundEnabled,
            ageGroup: _ageGroup,
            difficulty: _difficulty,
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
            artworks: artworks,
            audio: _audio,
          ),
          StudioTab.parent => ParentPage(
            onBack: () => setState(() => tab = StudioTab.home),
            usageSeconds: _usageSeconds,
            artworkCount: artworks.where((item) => item.isUserCreated).length,
            favoriteCount: artworks.where((item) => item.isFavorite).length,
            completedLessons: _drawingLessons
                .where(
                  (lesson) =>
                      (_lessonProgress[lesson.id] ?? 0) >= lesson.steps.length,
                )
                .length,
            soundEnabled: _soundEnabled,
            musicEnabled: _musicEnabled,
            ageGroup: _ageGroup,
            difficulty: _difficulty,
            onSoundChanged: (value) {
              _soundEnabled = value;
              _savePreference('soundEnabled', value);
              unawaited(_audio.setSoundEnabled(value));
            },
            onMusicChanged: (value) {
              _musicEnabled = value;
              _savePreference('musicEnabled', value);
              unawaited(_audio.setMusicEnabled(value));
            },
            onAgeChanged: (value) {
              _ageGroup = value;
              _savePreference('ageGroup', value);
            },
            onDifficultyChanged: (value) {
              _difficulty = value;
              _savePreference('difficulty', value);
            },
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
    final effectiveSelected = selected == StudioTab.coloring
        ? StudioTab.draw
        : selected;
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
              selected: effectiveSelected == item.$1,
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
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
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
    final effectiveSelected = selected == StudioTab.coloring
        ? StudioTab.draw
        : selected;
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
          items.indexWhere((item) => item.$1 == effectiveSelected),
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

class LittleArtistOnboarding extends StatefulWidget {
  const LittleArtistOnboarding({super.key});

  @override
  State<LittleArtistOnboarding> createState() => _LittleArtistOnboardingState();
}

class _LittleArtistOnboardingState extends State<LittleArtistOnboarding> {
  int _page = 0;

  static const _pages = [
    ('🎨', '欢迎来到小小画室', '自由画画、趣味涂色和分步课程，都可以离线使用。'),
    ('✨', '每次创作都有惊喜', '完成作品会获得创作星星，还能让自己的画跳舞、飞行和回放。'),
    ('🛡️', '专为孩子安心设计', '没有广告和外部链接；声音、音乐、年龄推荐都由家长管理。'),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(30, 28, 30, 16),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(page.$1, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(
              page.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              page.$3,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _pages.length; index++)
                  Container(
                    width: index == _page ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _page ? _orange : const Color(0xFFE4D7CB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_page > 0)
          TextButton(
            onPressed: () => setState(() => _page--),
            child: const Text('上一步'),
          ),
        FilledButton(
          key: const ValueKey('onboarding-next'),
          onPressed: () {
            if (_page == _pages.length - 1) {
              Navigator.pop(context);
            } else {
              setState(() => _page++);
            }
          },
          child: Text(_page == _pages.length - 1 ? '开始创作' : '下一步'),
        ),
      ],
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.artworks,
    required this.streak,
    required this.creationStars,
    required this.onOpen,
  });

  final List<GalleryArtwork> artworks;
  final int streak;
  final int creationStars;
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
              HeroGreeting(
                streak: streak,
                creationStars: creationStars,
                onParent: () => onOpen(StudioTab.parent),
              ),
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
                crossAxisCount: isTablet ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: isTablet ? 18 : 20,
                crossAxisSpacing: isTablet ? 18 : 20,
                childAspectRatio: isTablet ? 1.75 : .98,
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
                    title: '涂色乐园',
                    subtitle: '放心涂，不出界',
                    icon: Icons.format_color_fill_rounded,
                    iconColor: const Color(0xFF235E8F),
                    color: const Color(0xFFD8EEFF),
                    onTap: () => onOpen(StudioTab.coloring),
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
                    title: '今日挑战',
                    subtitle: '完成彩虹蝴蝶',
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFF8A5310),
                    color: const Color(0xFFFFE4A6),
                    onTap: () => onOpen(StudioTab.coloring),
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
                  itemCount: math.min(artworks.length, 6),
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) =>
                      RecentCard(artwork: artworks[index], compact: isTablet),
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
  const HeroGreeting({
    super.key,
    required this.streak,
    required this.creationStars,
    required this.onParent,
  });

  final int streak;
  final int creationStars;
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
          if (streak > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _butter,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '⭐ $creationStars · 🔥 $streak 天',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
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
    this.replayData,
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
  final Map<String, Object?>? replayData;

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
      replayData: replayData,
    );
  }
}

String _artworkSourceLabel(GalleryArtwork artwork) {
  if (!artwork.isUserCreated) return '示例作品';
  return switch (artwork.source) {
    'lesson' => '课程作品',
    'coloring' => '涂色作品',
    _ => '自由创作',
  };
}

class RecentCard extends StatelessWidget {
  const RecentCard({super.key, required this.artwork, this.compact = false});

  final GalleryArtwork artwork;
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ColoredBox(
                color: artwork.color,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: artwork.pngBytes != null
                      ? Image.memory(artwork.pngBytes!, fit: BoxFit.contain)
                      : CustomPaint(
                          painter: SketchPainter(
                            artwork.kind ?? SketchKind.sun,
                          ),
                          child: const SizedBox.expand(),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            artwork.title,
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

enum ColoringTemplate { butterfly, rabbit, pony, penguin, fish, flower, rocket }

extension ColoringTemplateInfo on ColoringTemplate {
  String get title => switch (this) {
    ColoringTemplate.butterfly => '彩虹蝴蝶',
    ColoringTemplate.rabbit => '软萌小兔',
    ColoringTemplate.pony => '草原小马',
    ColoringTemplate.penguin => '圆滚企鹅',
    ColoringTemplate.fish => '海底小鱼',
    ColoringTemplate.flower => '微笑花朵',
    ColoringTemplate.rocket => '太空火箭',
  };

  String get emoji => switch (this) {
    ColoringTemplate.butterfly => '🦋',
    ColoringTemplate.rabbit => '🐰',
    ColoringTemplate.pony => '🐴',
    ColoringTemplate.penguin => '🐧',
    ColoringTemplate.fish => '🐠',
    ColoringTemplate.flower => '🌼',
    ColoringTemplate.rocket => '🚀',
  };
}

class _ColoringRegion {
  const _ColoringRegion(this.path, this.baseColor);

  final Path path;
  final Color baseColor;
}

List<_ColoringRegion> _coloringRegions(ColoringTemplate template) {
  Path oval(double left, double top, double right, double bottom) =>
      Path()..addOval(Rect.fromLTRB(left, top, right, bottom));

  switch (template) {
    case ColoringTemplate.butterfly:
      return [
        _ColoringRegion(
          Path()
            ..moveTo(288, 210)
            ..cubicTo(235, 66, 70, 58, 85, 190)
            ..cubicTo(92, 257, 184, 269, 288, 240)
            ..close(),
          const Color(0xFFFFD8D0),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(312, 210)
            ..cubicTo(365, 66, 530, 58, 515, 190)
            ..cubicTo(508, 257, 416, 269, 312, 240)
            ..close(),
          const Color(0xFFD8EEFF),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(286, 238)
            ..cubicTo(170, 232, 88, 286, 118, 360)
            ..cubicTo(149, 410, 246, 350, 292, 270)
            ..close(),
          const Color(0xFFFFEAB0),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(314, 238)
            ..cubicTo(430, 232, 512, 286, 482, 360)
            ..cubicTo(451, 410, 354, 350, 308, 270)
            ..close(),
          const Color(0xFFD2F2DC),
        ),
        _ColoringRegion(oval(275, 126, 325, 350), const Color(0xFFFFA45B)),
        _ColoringRegion(oval(155, 135, 215, 195), Colors.white),
        _ColoringRegion(oval(385, 135, 445, 195), Colors.white),
      ];
    case ColoringTemplate.rabbit:
      return [
        _ColoringRegion(oval(210, 190, 390, 425), const Color(0xFFD8EEFF)),
        _ColoringRegion(oval(190, 90, 410, 305), const Color(0xFFFFF4EA)),
        _ColoringRegion(oval(215, 15, 285, 165), const Color(0xFFFFD8D0)),
        _ColoringRegion(oval(315, 15, 385, 165), const Color(0xFFFFD8D0)),
        _ColoringRegion(oval(245, 235, 355, 390), const Color(0xFFFFF9F0)),
        _ColoringRegion(oval(175, 345, 275, 425), const Color(0xFFFFEAB0)),
        _ColoringRegion(oval(325, 345, 425, 425), const Color(0xFFFFEAB0)),
        _ColoringRegion(oval(216, 210, 260, 250), const Color(0xFFFFB6B1)),
        _ColoringRegion(oval(340, 210, 384, 250), const Color(0xFFFFB6B1)),
      ];
    case ColoringTemplate.pony:
      return [
        _ColoringRegion(oval(150, 150, 445, 335), const Color(0xFFFFE2B8)),
        _ColoringRegion(oval(72, 92, 245, 250), const Color(0xFFFFE2B8)),
        _ColoringRegion(oval(52, 165, 175, 245), const Color(0xFFFFD8D0)),
        _ColoringRegion(
          Path()
            ..moveTo(116, 105)
            ..cubicTo(155, 35, 245, 65, 252, 177)
            ..cubicTo(215, 135, 184, 130, 142, 154)
            ..close(),
          const Color(0xFFFF9D77),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(425, 185)
            ..cubicTo(540, 130, 558, 225, 472, 276)
            ..cubicTo(530, 265, 548, 310, 463, 323)
            ..close(),
          const Color(0xFFFF9D77),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(190, 305)
            ..lineTo(245, 305)
            ..lineTo(235, 425)
            ..lineTo(180, 425)
            ..close(),
          const Color(0xFFD8EEFF),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(350, 305)
            ..lineTo(405, 305)
            ..lineTo(420, 425)
            ..lineTo(365, 425)
            ..close(),
          const Color(0xFFD8EEFF),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(155, 102)
            ..lineTo(170, 36)
            ..lineTo(212, 105)
            ..close(),
          const Color(0xFFFFD8D0),
        ),
        _ColoringRegion(oval(245, 178, 365, 275), const Color(0xFFD2F2DC)),
      ];
    case ColoringTemplate.penguin:
      return [
        _ColoringRegion(oval(185, 35, 415, 415), const Color(0xFF7E89A6)),
        _ColoringRegion(
          Path()
            ..moveTo(205, 155)
            ..cubicTo(115, 210, 120, 345, 220, 325)
            ..close(),
          const Color(0xFF8C9ABA),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(395, 155)
            ..cubicTo(485, 210, 480, 345, 380, 325)
            ..close(),
          const Color(0xFF8C9ABA),
        ),
        _ColoringRegion(oval(225, 145, 375, 395), const Color(0xFFFFF7E9)),
        _ColoringRegion(
          Path()
            ..moveTo(270, 160)
            ..lineTo(330, 160)
            ..lineTo(300, 205)
            ..close(),
          const Color(0xFFFFB347),
        ),
        _ColoringRegion(oval(195, 365, 295, 425), const Color(0xFFFFC85B)),
        _ColoringRegion(oval(305, 365, 405, 425), const Color(0xFFFFC85B)),
        _ColoringRegion(oval(230, 115, 270, 150), Colors.white),
        _ColoringRegion(oval(330, 115, 370, 150), Colors.white),
      ];
    case ColoringTemplate.fish:
      return [
        _ColoringRegion(oval(105, 120, 455, 340), const Color(0xFFD8EEFF)),
        _ColoringRegion(
          Path()
            ..moveTo(438, 195)
            ..lineTo(555, 112)
            ..lineTo(535, 230)
            ..lineTo(558, 345)
            ..lineTo(438, 270)
            ..close(),
          const Color(0xFFFFD8D0),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(250, 133)
            ..quadraticBezierTo(330, 52, 387, 145)
            ..close(),
          const Color(0xFFFFEAB0),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(255, 328)
            ..quadraticBezierTo(330, 405, 390, 318)
            ..close(),
          const Color(0xFFD2F2DC),
        ),
        _ColoringRegion(oval(160, 174, 214, 228), Colors.white),
      ];
    case ColoringTemplate.flower:
      return [
        _ColoringRegion(oval(245, 45, 355, 180), const Color(0xFFFFD8D0)),
        _ColoringRegion(oval(330, 105, 455, 220), const Color(0xFFD8EEFF)),
        _ColoringRegion(oval(315, 205, 430, 325), const Color(0xFFD2F2DC)),
        _ColoringRegion(oval(170, 205, 285, 325), const Color(0xFFFFEAB0)),
        _ColoringRegion(oval(145, 105, 270, 220), const Color(0xFFF2DEE8)),
        _ColoringRegion(oval(235, 145, 365, 275), const Color(0xFFFFC85B)),
        _ColoringRegion(
          Path()
            ..moveTo(284, 275)
            ..lineTo(316, 275)
            ..lineTo(320, 430)
            ..lineTo(280, 430)
            ..close(),
          const Color(0xFF83D39C),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(285, 330)
            ..quadraticBezierTo(175, 285, 170, 365)
            ..quadraticBezierTo(235, 392, 285, 360)
            ..close(),
          const Color(0xFFD2F2DC),
        ),
      ];
    case ColoringTemplate.rocket:
      return [
        _ColoringRegion(
          Path()
            ..moveTo(300, 42)
            ..cubicTo(225, 108, 225, 270, 250, 335)
            ..lineTo(350, 335)
            ..cubicTo(375, 270, 375, 108, 300, 42)
            ..close(),
          const Color(0xFFD8EEFF),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(250, 245)
            ..lineTo(165, 345)
            ..lineTo(255, 326)
            ..close(),
          const Color(0xFFFFD8D0),
        ),
        _ColoringRegion(
          Path()
            ..moveTo(350, 245)
            ..lineTo(435, 345)
            ..lineTo(345, 326)
            ..close(),
          const Color(0xFFFFD8D0),
        ),
        _ColoringRegion(oval(257, 140, 343, 226), const Color(0xFFFFEAB0)),
        _ColoringRegion(
          Path()
            ..moveTo(273, 335)
            ..quadraticBezierTo(300, 430, 327, 335)
            ..close(),
          const Color(0xFFFFA45B),
        ),
      ];
  }
}

class ColoringPage extends StatefulWidget {
  const ColoringPage({super.key, required this.onBack, required this.onSaved});

  final VoidCallback onBack;
  final Future<void> Function(String title, Uint8List pngBytes) onSaved;

  @override
  State<ColoringPage> createState() => _ColoringPageState();
}

class _ColoringPageState extends State<ColoringPage> {
  final _canvasKey = GlobalKey();
  final Map<ColoringTemplate, Map<int, Color>> _fills = {};
  ColoringTemplate _template = ColoringTemplate.butterfly;
  Color _selectedColor = _orange;
  bool _saving = false;

  Map<int, Color> get _currentFills =>
      _fills.putIfAbsent(_template, () => <int, Color>{});

  void _fillAt(Offset localPosition) {
    final renderBox = _canvasKey.currentContext?.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;
    final point = Offset(
      localPosition.dx * 600 / renderBox.size.width,
      localPosition.dy * 440 / renderBox.size.height,
    );
    final regions = _coloringRegions(_template);
    for (var index = regions.length - 1; index >= 0; index--) {
      if (regions[index].path.contains(point)) {
        setState(() => _currentFills[index] = _selectedColor);
        return;
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('无法生成涂色作品');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await widget.onSaved(_template.title, bytes);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Text('🌟', style: TextStyle(fontSize: 48)),
          title: const Text('太棒啦！'),
          content: Text('「${_template.title}」已经保存到作品集，获得一颗创作星星！'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('继续创作'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请检查设备存储空间')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '涂色乐园',
      onBack: widget.onBack,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          final picker = ColoringTemplatePicker(
            selected: _template,
            horizontal: !isWide,
            onSelected: (template) => setState(() => _template = template),
          );
          final palette = ColoringPalette(
            selected: _selectedColor,
            horizontal: !isWide,
            saving: _saving,
            onSelected: (color) => setState(() => _selectedColor = color),
            onUndo: _currentFills.isEmpty
                ? null
                : () => setState(
                    () => _currentFills.remove(_currentFills.keys.last),
                  ),
            onClear: _currentFills.isEmpty
                ? null
                : () => setState(_currentFills.clear),
            onSave: _save,
          );
          final canvas = RepaintBoundary(
            key: _canvasKey,
            child: GestureDetector(
              key: const ValueKey('coloring-canvas'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _fillAt(details.localPosition),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: ColoredBox(
                  color: Colors.white,
                  child: CustomPaint(
                    painter: ColoringPainter(
                      template: _template,
                      fills: Map.of(_currentFills),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 170, child: picker),
                const SizedBox(width: 14),
                Expanded(child: canvas),
                const SizedBox(width: 14),
                SizedBox(width: 158, child: palette),
              ],
            );
          }
          return Column(
            children: [
              SizedBox(height: 70, child: picker),
              const SizedBox(height: 10),
              Expanded(child: canvas),
              const SizedBox(height: 10),
              SizedBox(height: 108, child: palette),
            ],
          );
        },
      ),
    );
  }
}

class ColoringTemplatePicker extends StatelessWidget {
  const ColoringTemplatePicker({
    super.key,
    required this.selected,
    required this.horizontal,
    required this.onSelected,
  });

  final ColoringTemplate selected;
  final bool horizontal;
  final ValueChanged<ColoringTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget templateItem(ColoringTemplate template) => InkWell(
      key: ValueKey('coloring-template-${template.name}'),
      borderRadius: BorderRadius.circular(17),
      onTap: () => onSelected(template),
      child: Container(
        width: horizontal ? 76 : double.infinity,
        height: horizontal ? double.infinity : 58,
        decoration: BoxDecoration(
          color: selected == template
              ? const Color(0xFFFFE3DC)
              : const Color(0xFFF8F1E8),
          borderRadius: BorderRadius.circular(17),
          border: selected == template
              ? Border.all(color: _orange, width: 2)
              : null,
        ),
        child: horizontal
            ? Center(
                child: Text(
                  template.emoji,
                  style: const TextStyle(fontSize: 25),
                ),
              )
            : Row(
                children: [
                  const SizedBox(width: 10),
                  Text(template.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: horizontal
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ColoringTemplate.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 7),
              itemBuilder: (context, index) =>
                  templateItem(ColoringTemplate.values[index]),
            )
          : Column(
              children: [
                const Text(
                  '选一幅画',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: ColoringTemplate.values.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        templateItem(ColoringTemplate.values[index]),
                  ),
                ),
              ],
            ),
    );
  }
}

class ColoringPalette extends StatelessWidget {
  const ColoringPalette({
    super.key,
    required this.selected,
    required this.horizontal,
    required this.saving,
    required this.onSelected,
    required this.onUndo,
    required this.onClear,
    required this.onSave,
  });

  final Color selected;
  final bool horizontal;
  final bool saving;
  final ValueChanged<Color> onSelected;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    const colors = [
      _orange,
      Color(0xFFFFA600),
      Color(0xFFFF79A8),
      Color(0xFF20B26B),
      Color(0xFF45A7E8),
      Color(0xFF8C63E8),
      Color(0xFF3A1D10),
      Color(0xFFFFFFFF),
    ];
    final colorButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final color in colors)
          InkWell(
            onTap: () => onSelected(color),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == color ? _ink : const Color(0xFFE8D9CA),
                  width: selected == color ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: horizontal
          ? Row(
              children: [
                Expanded(child: colorButtons),
                IconButton(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded),
                ),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: const Icon(Icons.star_rounded),
                  label: Text(saving ? '保存中' : '完成'),
                ),
              ],
            )
          : Column(
              children: [
                const Text(
                  '选颜色',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                colorButtons,
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: onUndo,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('coloring-save'),
                    onPressed: saving ? null : onSave,
                    icon: const Icon(Icons.star_rounded),
                    label: Text(saving ? '保存中…' : '完成作品'),
                  ),
                ),
              ],
            ),
    );
  }
}

class ColoringPainter extends CustomPainter {
  const ColoringPainter({required this.template, required this.fills});

  final ColoringTemplate template;
  final Map<int, Color> fills;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFEFB),
    );
    canvas.save();
    canvas.scale(size.width / 600, size.height / 440);
    final regions = _coloringRegions(template);
    for (var index = 0; index < regions.length; index++) {
      final region = regions[index];
      canvas.drawPath(
        region.path,
        Paint()..color = fills[index] ?? region.baseColor,
      );
      canvas.drawPath(
        region.path,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final detail = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    switch (template) {
      case ColoringTemplate.butterfly:
        canvas.drawArc(
          const Rect.fromLTRB(265, 78, 300, 145),
          math.pi,
          math.pi,
          false,
          detail,
        );
        canvas.drawArc(
          const Rect.fromLTRB(300, 78, 335, 145),
          math.pi,
          math.pi,
          false,
          detail,
        );
      case ColoringTemplate.rabbit:
        canvas.drawCircle(const Offset(257, 183), 7, Paint()..color = _ink);
        canvas.drawCircle(const Offset(343, 183), 7, Paint()..color = _ink);
        canvas.drawPath(
          Path()
            ..moveTo(290, 215)
            ..lineTo(310, 215)
            ..lineTo(300, 229)
            ..close(),
          Paint()..color = _orange,
        );
        canvas.drawArc(
          const Rect.fromLTRB(270, 218, 300, 250),
          0,
          math.pi,
          false,
          detail,
        );
        canvas.drawArc(
          const Rect.fromLTRB(300, 218, 330, 250),
          0,
          math.pi,
          false,
          detail,
        );
      case ColoringTemplate.pony:
        canvas.drawCircle(const Offset(138, 143), 7, Paint()..color = _ink);
        canvas.drawCircle(const Offset(90, 202), 5, Paint()..color = _ink);
        canvas.drawArc(
          const Rect.fromLTRB(102, 188, 160, 230),
          .2,
          1.2,
          false,
          detail,
        );
        canvas.drawLine(const Offset(195, 395), const Offset(232, 395), detail);
        canvas.drawLine(const Offset(370, 395), const Offset(410, 395), detail);
      case ColoringTemplate.penguin:
        canvas.drawCircle(const Offset(250, 132), 6, Paint()..color = _ink);
        canvas.drawCircle(const Offset(350, 132), 6, Paint()..color = _ink);
        canvas.drawArc(
          const Rect.fromLTRB(270, 205, 330, 252),
          0,
          math.pi,
          false,
          detail,
        );
      case ColoringTemplate.fish:
        canvas.drawCircle(const Offset(187, 201), 7, Paint()..color = _ink);
        canvas.drawArc(
          const Rect.fromLTRB(120, 220, 185, 275),
          -.8,
          1.55,
          false,
          detail,
        );
      case ColoringTemplate.flower:
        canvas.drawCircle(const Offset(275, 190), 7, Paint()..color = _ink);
        canvas.drawCircle(const Offset(325, 190), 7, Paint()..color = _ink);
        canvas.drawArc(
          const Rect.fromLTRB(274, 198, 326, 238),
          0,
          math.pi,
          false,
          detail,
        );
      case ColoringTemplate.rocket:
        canvas.drawCircle(
          const Offset(300, 183),
          18,
          Paint()..color = Colors.white.withValues(alpha: .55),
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ColoringPainter oldDelegate) =>
      oldDelegate.template != template || oldDelegate.fills != fills;
}

class DrawPage extends StatefulWidget {
  const DrawPage({
    super.key,
    required this.onBack,
    required this.onSaved,
    required this.store,
  });
  final VoidCallback onBack;
  final Future<void> Function(Uint8List, Map<String, Object?>) onSaved;
  final ArtistStore store;

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final _canvasKey = GlobalKey();
  final _strokes = <DrawingStroke>[];
  final _redoStack = <DrawingStroke>[];
  DrawingStroke? _activeStroke;
  int? _activePointer;
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
    if (_activePointer != null) return;
    final stroke = DrawingStroke(
      tool: _tool,
      color: _tool == DrawingTool.eraser ? Colors.white : _color,
      baseWidth: _tool == DrawingTool.eraser ? _width * 2.4 : _width,
      points: [DrawingPoint(event.localPosition, _pressure(event))],
    );
    setState(() {
      _activePointer = event.pointer;
      _redoStack.clear();
      _activeStroke = _tool.isDiscrete ? null : stroke;
      _strokes.add(stroke);
    });
    if (_tool.isDiscrete) {
      _activePointer = null;
      _scheduleAutosave();
    }
  }

  void _extendStroke(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _tool.isDiscrete) return;
    setState(() {
      _activeStroke?.points.add(
        DrawingPoint(event.localPosition, _pressure(event)),
      );
    });
  }

  void _endStroke(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
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
      await widget.onSaved(
        bytes,
        _draftFromStrokes(_strokes, canvasSize: boundary.size),
      );
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

enum DrawingTool {
  crayon,
  marker,
  glow,
  eraser,
  spray,
  pattern,
  stamp,
  sticker,
  fill,
}

extension DrawingToolBehavior on DrawingTool {
  bool get isDiscrete =>
      this == DrawingTool.stamp ||
      this == DrawingTool.sticker ||
      this == DrawingTool.fill;
}

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
  Size? canvasSize,
}) => {
  'version': 1,
  'stepIndex': ?stepIndex,
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
  if (canvasSize != null) 'canvasWidth': canvasSize.width,
  if (canvasSize != null) 'canvasHeight': canvasSize.height,
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
                    icon: Icons.blur_on_rounded,
                    selected: tool == DrawingTool.spray,
                    onTap: () => onTool(DrawingTool.spray),
                    tooltip: '喷枪',
                  ),
                  ToolChip(
                    icon: Icons.texture_rounded,
                    selected: tool == DrawingTool.pattern,
                    onTap: () => onTool(DrawingTool.pattern),
                    tooltip: '图案笔',
                  ),
                  ToolChip(
                    icon: Icons.pets_rounded,
                    selected: tool == DrawingTool.stamp,
                    onTap: () => onTool(DrawingTool.stamp),
                    tooltip: '印章',
                  ),
                  ToolChip(
                    icon: Icons.emoji_emotions_rounded,
                    selected: tool == DrawingTool.sticker,
                    onTap: () => onTool(DrawingTool.sticker),
                    tooltip: '贴纸',
                  ),
                  ToolChip(
                    icon: Icons.format_color_fill_rounded,
                    selected: tool == DrawingTool.fill,
                    onTap: () => onTool(DrawingTool.fill),
                    tooltip: '填色桶',
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
    var paperColor = Colors.white;
    for (final stroke in strokes) {
      if (stroke.tool == DrawingTool.fill) paperColor = stroke.color;
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = paperColor);
    _drawPaperTexture(canvas, size);
    guide?.paint(canvas, size);

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      if (stroke.tool == DrawingTool.fill) continue;
      if (stroke.tool == DrawingTool.spray) {
        _drawSpray(canvas, stroke);
        continue;
      }
      if (stroke.tool == DrawingTool.pattern) {
        _drawPattern(canvas, stroke);
        continue;
      }
      if (stroke.tool == DrawingTool.stamp) {
        _drawStamp(canvas, stroke);
        continue;
      }
      if (stroke.tool == DrawingTool.sticker) {
        _drawSticker(canvas, stroke);
        continue;
      }
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

  void _drawSpray(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()..color = stroke.color.withValues(alpha: .62);
    for (var pointIndex = 0; pointIndex < stroke.points.length; pointIndex++) {
      final point = stroke.points[pointIndex].offset;
      final seed =
          point.dx.round() * 73856093 ^
          point.dy.round() * 19349663 ^
          pointIndex * 83492791;
      final random = math.Random(seed);
      for (var dot = 0; dot < 11; dot++) {
        final angle = random.nextDouble() * math.pi * 2;
        final radius = random.nextDouble() * stroke.baseWidth * 1.7;
        canvas.drawCircle(
          point + Offset(math.cos(angle), math.sin(angle)) * radius,
          math.max(1.1, stroke.baseWidth * (.07 + random.nextDouble() * .07)),
          paint,
        );
      }
    }
  }

  void _drawPattern(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill;
    final radius = math.max(3.0, stroke.baseWidth * .42);
    for (var i = 0; i < stroke.points.length; i += 3) {
      final center = stroke.points[i].offset;
      if (i.isEven) {
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(
          center,
          radius * .42,
          Paint()..color = Colors.white.withValues(alpha: .75),
        );
      } else {
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawStamp(Canvas canvas, DrawingStroke stroke) {
    final center = stroke.points.first.offset;
    final radius = math.max(8.0, stroke.baseWidth * 1.25);
    final paint = Paint()..color = stroke.color;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .35),
        width: radius * 1.45,
        height: radius * 1.2,
      ),
      paint,
    );
    for (final offset in const [
      Offset(-.62, -.55),
      Offset(-.20, -.82),
      Offset(.22, -.82),
      Offset(.64, -.55),
    ]) {
      canvas.drawCircle(center + offset * radius, radius * .27, paint);
    }
  }

  void _drawSticker(Canvas canvas, DrawingStroke stroke) {
    final center = stroke.points.first.offset;
    final outer = math.max(15.0, stroke.baseWidth * 2.1);
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : outer * .43;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = stroke.color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, outer * .10),
    );
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
    this.ageGroup = '4-6岁',
    this.difficulty = '入门',
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
  final String ageGroup;
  final String difficulty;
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
    ageGroup: '2-4岁',
    difficulty: '入门',
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
    ageGroup: '4-6岁',
    difficulty: '进阶',
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
    ageGroup: '4-6岁',
    difficulty: '入门',
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
    ageGroup: '6-8岁',
    difficulty: '挑战',
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
    required this.audio,
    required this.soundEnabled,
    required this.ageGroup,
    required this.difficulty,
  });
  final VoidCallback onBack;
  final Map<String, int> progress;
  final void Function(String lessonId, int completedSteps) onProgress;
  final Future<void> Function(DrawingLesson lesson, Uint8List pngBytes)
  onArtworkSaved;
  final ArtistStore store;
  final StudioAudio audio;
  final bool soundEnabled;
  final String ageGroup;
  final String difficulty;

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
              ageGroup: widget.ageGroup,
              difficulty: widget.difficulty,
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
              audio: widget.audio,
              soundEnabled: widget.soundEnabled,
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
    required this.ageGroup,
    required this.difficulty,
  });

  final String category;
  final Map<String, int> progress;
  final ValueChanged<String> onCategory;
  final ValueChanged<DrawingLesson> onOpen;
  final String ageGroup;
  final String difficulty;

  int _progressFor(DrawingLesson lesson) =>
      math.min(progress[lesson.id] ?? 0, lesson.steps.length);

  @override
  Widget build(BuildContext context) {
    const categories = ['全部', '可爱动物', '恐龙世界', '交通工具', '节日快乐'];
    final matchingCategory = category == '全部'
        ? _drawingLessons
        : _drawingLessons
              .where((lesson) => lesson.category == category)
              .toList();
    final visibleLessons = [...matchingCategory]
      ..sort((a, b) {
        final aScore =
            (a.ageGroup == ageGroup ? 2 : 0) +
            (a.difficulty == difficulty ? 1 : 0);
        final bScore =
            (b.ageGroup == ageGroup ? 2 : 0) +
            (b.difficulty == difficulty ? 1 : 0);
        return bScore.compareTo(aScore);
      });
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.recommend_rounded, color: _orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '已优先推荐 $ageGroup · $difficulty 课程',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
    required this.audio,
    required this.soundEnabled,
  });

  final DrawingLesson lesson;
  final int initialStep;
  final ValueChanged<int> onProgress;
  final VoidCallback onFinish;
  final Future<void> Function(Uint8List pngBytes) onArtworkSaved;
  final ArtistStore store;
  final StudioAudio audio;
  final bool soundEnabled;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentStep());
  }

  void _speakCurrentStep() {
    if (!widget.soundEnabled) return;
    final step = widget.lesson.steps[_stepIndex];
    unawaited(
      widget.audio.speak(
        '第 ${_stepIndex + 1} 步。${step.title}。${step.description}。${step.tip}',
      ),
    );
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
    _speakCurrentStep();
  }

  void _nextStep() {
    if (_stepIndex < widget.lesson.steps.length - 1) {
      widget.onProgress(_stepIndex + 1);
      setState(() => _stepIndex++);
      _scheduleAutosave();
      _speakCurrentStep();
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
      unawaited(widget.audio.success());
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
              IconButton.filledTonal(
                key: const ValueKey('lesson-speak-step'),
                tooltip: '朗读本步骤',
                onPressed: widget.soundEnabled ? _speakCurrentStep : null,
                icon: Icon(
                  widget.soundEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
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
                      '${_artworkSourceLabel(artwork)} · ${artwork.createdLabel}',
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
                value: _artworkSourceLabel(artwork),
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

enum ArtworkMotion { jump, blink, fly, replay }

extension ArtworkMotionInfo on ArtworkMotion {
  String get label => switch (this) {
    ArtworkMotion.jump => '跳一跳',
    ArtworkMotion.blink => '眨眼',
    ArtworkMotion.fly => '飞起来',
    ArtworkMotion.replay => '笔画回放',
  };

  IconData get icon => switch (this) {
    ArtworkMotion.jump => Icons.swap_vert_rounded,
    ArtworkMotion.blink => Icons.visibility_rounded,
    ArtworkMotion.fly => Icons.flight_takeoff_rounded,
    ArtworkMotion.replay => Icons.gesture_rounded,
  };
}

class AnimationPage extends StatefulWidget {
  const AnimationPage({
    super.key,
    required this.onBack,
    required this.artworks,
    required this.audio,
  });

  final VoidCallback onBack;
  final List<GalleryArtwork> artworks;
  final StudioAudio audio;

  @override
  State<AnimationPage> createState() => _AnimationPageState();
}

class _AnimationPageState extends State<AnimationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ArtworkMotion _motion = ArtworkMotion.jump;
  String? _selectedId;

  GalleryArtwork get _selected => widget.artworks.firstWhere(
    (item) => item.id == _selectedId,
    orElse: () => widget.artworks.first,
  );

  @override
  void initState() {
    super.initState();
    _selectedId = widget.artworks.first.id;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedArtwork() => AnimatedBuilder(
    animation: _controller,
    child: ArtworkThumbnail(artwork: _selected),
    builder: (context, child) {
      final value = _controller.value;
      final replayData = _selected.replayData;
      return switch (_motion) {
        ArtworkMotion.jump => Transform.translate(
          offset: Offset(0, -math.sin(value * math.pi).abs() * 90),
          child: child,
        ),
        ArtworkMotion.blink => Transform.scale(
          scaleY: value > .42 && value < .52 ? .10 : 1,
          child: child,
        ),
        ArtworkMotion.fly => Transform.translate(
          offset: Offset((value - .5) * 250, -math.sin(value * math.pi) * 80),
          child: Transform.rotate(angle: (value - .5) * .15, child: child),
        ),
        ArtworkMotion.replay when replayData != null => CustomPaint(
          painter: StrokeReplayPainter(
            replayData: replayData,
            progress: Curves.easeInOut.transform(value),
          ),
          child: const SizedBox.expand(),
        ),
        ArtworkMotion.replay => ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: Curves.easeInOut.transform(value).clamp(.04, 1),
            child: child,
          ),
        ),
      };
    },
  );

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '动画故事',
      onBack: widget.onBack,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final stage = Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE7E0FF), Color(0xFFD8F5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 28,
                  left: 36,
                  child: Text(
                    '✦',
                    style: TextStyle(fontSize: 35, color: _orange),
                  ),
                ),
                const Positioned(
                  bottom: 34,
                  right: 42,
                  child: Text(
                    '✧',
                    style: TextStyle(fontSize: 46, color: Color(0xFF8C63E8)),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 250,
                    child: _animatedArtwork(),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: IconButton.filled(
                    key: const ValueKey('animation-play-toggle'),
                    tooltip: _controller.isAnimating ? '暂停动画' : '播放动画',
                    onPressed: () => setState(() {
                      if (_controller.isAnimating) {
                        _controller.stop();
                      } else {
                        _controller.repeat();
                      }
                    }),
                    icon: Icon(
                      _controller.isAnimating
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ),
              ],
            ),
          );
          final controls = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: ListView(
              children: [
                const Text(
                  '选择一幅作品',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: math.min(widget.artworks.length, 8),
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final artwork = widget.artworks[index];
                      return InkWell(
                        key: ValueKey('animation-artwork-${artwork.id}'),
                        onTap: () => setState(() => _selectedId = artwork.id),
                        child: Container(
                          width: 86,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedId == artwork.id
                                  ? _orange
                                  : const Color(0xFFE8D9CA),
                              width: _selectedId == artwork.id ? 3 : 1,
                            ),
                          ),
                          child: ArtworkThumbnail(artwork: artwork),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择动画',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                for (final motion in ArtworkMotion.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: ChoiceChip(
                      key: ValueKey('animation-motion-${motion.name}'),
                      selected: _motion == motion,
                      selectedColor: _rose,
                      avatar: Icon(motion.icon, size: 19),
                      label: Text(motion.label),
                      onSelected: (_) {
                        setState(() => _motion = motion);
                        _controller.repeat(period: _controller.duration);
                        unawaited(widget.audio.tap());
                      },
                    ),
                  ),
              ],
            ),
          );
          if (wide) {
            return Row(
              children: [
                Expanded(child: stage),
                const SizedBox(width: 16),
                SizedBox(width: 300, child: controls),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: stage),
              const SizedBox(height: 12),
              SizedBox(height: 245, child: controls),
            ],
          );
        },
      ),
    );
  }
}

class StrokeReplayPainter extends CustomPainter {
  StrokeReplayPainter({required this.replayData, required this.progress});

  final Map<String, Object?> replayData;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokes = _strokesFromDraft(replayData);
    if (strokes.isEmpty) return;
    final sourceSize = Size(
      (replayData['canvasWidth'] as num?)?.toDouble() ?? size.width,
      (replayData['canvasHeight'] as num?)?.toDouble() ?? size.height,
    );
    final pointCount = strokes.fold<int>(
      0,
      (total, stroke) => total + stroke.points.length,
    );
    var remaining = math.max(1, (pointCount * progress).ceil());
    final visible = <DrawingStroke>[];
    for (final stroke in strokes) {
      if (remaining <= 0) break;
      final count = math.min(remaining, stroke.points.length);
      visible.add(
        DrawingStroke(
          tool: stroke.tool,
          color: stroke.color,
          baseWidth: stroke.baseWidth,
          points: stroke.points.take(count).toList(),
        ),
      );
      remaining -= count;
    }

    final scale = math.min(
      size.width / sourceSize.width,
      size.height / sourceSize.height,
    );
    final paintedSize = Size(
      sourceSize.width * scale,
      sourceSize.height * scale,
    );
    canvas.save();
    canvas.translate(
      (size.width - paintedSize.width) / 2,
      (size.height - paintedSize.height) / 2,
    );
    canvas.scale(scale);
    NativeCanvasPainter(strokes: visible).paint(canvas, sourceSize);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StrokeReplayPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.replayData != replayData;
}

class ParentPage extends StatefulWidget {
  const ParentPage({
    super.key,
    required this.onBack,
    required this.usageSeconds,
    required this.artworkCount,
    required this.favoriteCount,
    required this.completedLessons,
    required this.soundEnabled,
    required this.musicEnabled,
    required this.ageGroup,
    required this.difficulty,
    required this.onSoundChanged,
    required this.onMusicChanged,
    required this.onAgeChanged,
    required this.onDifficultyChanged,
  });

  final VoidCallback onBack;
  final int usageSeconds;
  final int artworkCount;
  final int favoriteCount;
  final int completedLessons;
  final bool soundEnabled;
  final bool musicEnabled;
  final String ageGroup;
  final String difficulty;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onMusicChanged;
  final ValueChanged<String> onAgeChanged;
  final ValueChanged<String> onDifficultyChanged;

  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  bool _verified = false;

  String get _usageLabel {
    final minutes = widget.usageSeconds ~/ 60;
    return minutes < 1 ? '不足 1 分钟' : '$minutes 分钟';
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '家长中心',
      onBack: widget.onBack,
      child: _verified ? _dashboard() : _gate(),
    );
  }

  Widget _gate() => Center(
    child: Container(
      width: 430,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded, size: 54, color: _brown),
          const SizedBox(height: 14),
          const Text(
            '请家长回答',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            '12 + 7 等于多少？',
            style: TextStyle(color: _muted, fontSize: 16),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final answer in [17, 19, 21]) ...[
                FilledButton.tonal(
                  key: ValueKey('parent-answer-$answer'),
                  onPressed: () {
                    if (answer == 19) {
                      setState(() => _verified = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('答案不对，请再想一想')),
                      );
                    }
                  },
                  child: Text('$answer'),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    ),
  );

  Widget _dashboard() => ListView(
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ParentStat(
            icon: Icons.schedule_rounded,
            label: '累计使用',
            value: _usageLabel,
          ),
          ParentStat(
            icon: Icons.photo_library_rounded,
            label: '孩子作品',
            value: '${widget.artworkCount} 幅',
          ),
          ParentStat(
            icon: Icons.menu_book_rounded,
            label: '完成课程',
            value: '${widget.completedLessons} 节',
          ),
          ParentStat(
            icon: Icons.favorite_rounded,
            label: '收藏作品',
            value: '${widget.favoriteCount} 幅',
          ),
        ],
      ),
      const SizedBox(height: 16),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  '语音提示与音效',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('课程朗读、点击声和完成鼓励'),
                value: widget.soundEnabled,
                onChanged: widget.onSoundChanged,
              ),
              SwitchListTile(
                title: const Text(
                  '舒缓背景音乐',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('绘画时循环播放，可随时关闭'),
                value: widget.musicEnabled,
                onChanged: widget.onMusicChanged,
              ),
              const Divider(),
              ListTile(
                title: const Text(
                  '推荐年龄',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                trailing: DropdownButton<String>(
                  value: widget.ageGroup,
                  items: ['2-4岁', '4-6岁', '6-8岁']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) widget.onAgeChanged(value);
                  },
                ),
              ),
              ListTile(
                title: const Text(
                  '课程难度',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                trailing: DropdownButton<String>(
                  value: widget.difficulty,
                  items: ['入门', '进阶', '挑战']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) widget.onDifficultyChanged(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class ParentStat extends StatelessWidget {
  const ParentStat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 210,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Icon(icon, color: _orange, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
