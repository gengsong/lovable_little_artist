import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/local_artist_store.dart';
import 'package:lovable_little_artist/main.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pinchZoom(WidgetTester tester, Finder target) async {
    final center = tester.getCenter(target);
    final firstFinger = await tester.createGesture(pointer: 21);
    final secondFinger = await tester.createGesture(pointer: 22);
    await firstFinger.down(center - const Offset(22, 0));
    await secondFinger.down(center + const Offset(22, 0));
    await tester.pump();
    await firstFinger.moveTo(center - const Offset(88, 0));
    await secondFinger.moveTo(center + const Offset(88, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();
  }

  setUp(() {
    binding.platformDispatcher.localeTestValue = const Locale('zh');
    binding.platformDispatcher.localesTestValue = const [Locale('zh')];
  });

  tearDown(() {
    binding.platformDispatcher.clearLocaleTestValue();
    binding.platformDispatcher.clearLocalesTestValue();
  });

  testWidgets('shows Lovable-inspired home screen', (
    WidgetTester tester,
  ) async {
    final store = MemoryArtistStore();
    await tester.pumpWidget(LittleArtistVerseApp(store: store));

    expect(find.text('米娅!'), findsOneWidget);
    expect(find.text('今天想做什么？'), findsOneWidget);
    expect(find.text('自由画画'), findsOneWidget);
    expect(find.text('跟着学画'), findsOneWidget);
    expect(find.text('最近画的'), findsOneWidget);
  });

  testWidgets('studio rail fits the iPad mini safe area', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 33);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.pumpAndSettle();

    expect(find.byType(StudioRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('follows the system language and persists manual switching', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    binding.platformDispatcher.localeTestValue = const Locale('en');
    binding.platformDispatcher.localesTestValue = const [Locale('en')];
    final store = MemoryArtistStore();

    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('What would you like to make?'), findsOneWidget);
    expect(find.text('Free Draw'), findsOneWidget);
    expect(find.text('今天想做什么？'), findsNothing);
    expect(find.text('中文'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('中文').first);
    await tester.pumpAndSettle();
    expect(find.text('今天想做什么？'), findsOneWidget);
    expect(find.text('EN'), findsNWidgets(2));
    expect((await store.load()).preferences['localeMode'], 'zh');
    expect(tester.takeException(), isNull);
  });

  testWidgets('major English screens do not leak Chinese interface text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    binding.platformDispatcher.localeTestValue = const Locale('en');
    binding.platformDispatcher.localesTestValue = const [Locale('en')];

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.pumpAndSettle();

    void expectNoChineseText() {
      final leaked = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data ?? '')
          .where((text) => RegExp(r'[\u3400-\u9fff]').hasMatch(text))
          .where((text) => text != '中文')
          .toList();
      expect(leaked, isEmpty);
      expect(tester.takeException(), isNull);
    }

    expectNoChineseText();
    for (final destination in [
      'Free Draw',
      'Coloring Garden',
      'Learn to Draw',
      "Today's Challenge",
      'My Gallery',
      'Animate Artwork',
    ]) {
      await tester.tap(find.text(destination).first);
      await tester.pump(const Duration(milliseconds: 100));
      expectNoChineseText();
      await tester.tap(find.byKey(const ValueKey('app-page-back')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Parents'));
    await tester.pumpAndSettle();
    expectNoChineseText();
    await tester.tap(find.byKey(const ValueKey('parent-answer-19')));
    await tester.pumpAndSettle();
    expect(find.text('Display Language'), findsOneWidget);
    expect(find.text('Follow System'), findsOneWidget);
    expectNoChineseText();
  });

  testWidgets('guided lesson keeps progress and completes on iPad landscape', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.tap(find.text('跟着学画'));
    await tester.pumpAndSettle();

    expect(find.text('从一笔开始，画出大世界'), findsOneWidget);
    expect(find.byKey(const ValueKey('lesson-card-round-cat')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('lesson-continue')));
    await tester.pumpAndSettle();

    expect(find.text('第 1 / 4 步'), findsOneWidget);
    expect(find.text('画一个大圆'), findsOneWidget);

    await pinchZoom(tester, find.byKey(const ValueKey('lesson-guided-canvas')));
    expect(find.byKey(const ValueKey('lesson-reset-view')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-reset-view')));
    await tester.pump();
    expect(find.byKey(const ValueKey('lesson-reset-view')), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('lesson-guided-canvas')),
      const Offset(80, 30),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('撤销'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('lesson-next-step')));
    await tester.pump();
    expect(find.text('第 2 / 4 步'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('app-page-back')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 4 步'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lesson-continue')));
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 4 步'), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('lesson-next-step')));
      await tester.pump();
    }
    expect(find.text('第 4 / 4 步'), findsOneWidget);
    expect(find.text('完成课程'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lesson-next-step')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.text('画好啦！'), findsOneWidget);
    expect(find.textContaining('自动保存到作品集'), findsOneWidget);

    await tester.tap(find.text('返回课程'));
    await tester.pumpAndSettle();
    expect(find.text('已完成 1 幅'), findsOneWidget);

    await tester.tap(find.text('作品集'));
    await tester.pumpAndSettle();
    expect(find.text('课程作品 · 圆脸小猫'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('free drawing draft is restored after leaving the page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryArtistStore();

    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('free-drawing-canvas')),
      const Offset(90, 45),
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();

    expect(find.text('已恢复上次自动保存的草稿'), findsOneWidget);
    expect(find.byTooltip('撤销'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('free drawing canvas stays fixed while drawing', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('free-drawing-canvas'));
    final before = tester.getRect(canvas);
    expect(find.byType(InteractiveViewer), findsNothing);

    await tester.drag(canvas, const Offset(120, 70));
    await tester.pump();

    expect(tester.getRect(canvas), before);
    expect(find.byTooltip('撤销'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('free drawing canvas supports two finger zoom and reset', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('free-drawing-canvas'));
    final center = tester.getCenter(canvas);
    final firstFinger = await tester.createGesture(pointer: 11);
    final secondFinger = await tester.createGesture(pointer: 12);

    await firstFinger.down(center - const Offset(24, 0));
    await secondFinger.down(center + const Offset(24, 0));
    await tester.pump();
    await firstFinger.moveTo(center - const Offset(96, 0));
    await secondFinger.moveTo(center + const Offset(96, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('free-drawing-reset-view')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('free-drawing-reset-view')));
    await tester.pump();
    expect(find.byKey(const ValueKey('free-drawing-reset-view')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('advanced drawing tools are selectable and undoable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();

    for (final tool in ['喷枪', '图案笔', '印章', '贴纸', '填色桶']) {
      expect(find.byTooltip(tool), findsOneWidget);
    }

    await tester.tap(find.byTooltip('填色桶'));
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('free-drawing-canvas'))),
    );
    await tester.pump();
    expect(find.byTooltip('撤销'), findsOneWidget);
    await tester.tap(find.byTooltip('撤销'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('stickers can move and return through undo history', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryArtistStore();
    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('drawing-layer-background')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('drawing-layer-artwork')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('drawing-layer-stickers')),
      findsOneWidget,
    );

    final canvas = find.byKey(const ValueKey('free-drawing-canvas'));
    final canvasRect = tester.getRect(canvas);
    final center = tester.getCenter(canvas);
    await tester.tap(find.byTooltip('贴纸'));
    await tester.tapAt(center);
    await tester.pump();
    await tester.dragFrom(center, const Offset(80, 40));
    await tester.pump();
    await tester.tap(find.byTooltip('撤销'));
    await tester.pump();
    await tester.tap(find.byTooltip('保存预览'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    final replayData = (await store.load()).artworks.single.replayData!;
    final strokes = replayData['strokes'] as List<dynamic>;
    final sticker = (strokes.single as Map).cast<String, dynamic>();
    final point = (sticker['points'] as List).single as List<dynamic>;

    expect(sticker['tool'], 'sticker');
    expect(sticker['layer'], 'stickers');
    expect((point[0] as num).toDouble(), closeTo(canvasRect.width / 2, 1));
    expect((point[1] as num).toDouble(), closeTo(canvasRect.height / 2, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stickers can be scaled with a second finger', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryArtistStore();
    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('free-drawing-canvas'));
    final center = tester.getCenter(canvas);
    await tester.tap(find.byTooltip('贴纸'));
    await tester.tapAt(center);
    await tester.pump();

    final firstFinger = await tester.createGesture(pointer: 31);
    final secondFinger = await tester.createGesture(pointer: 32);
    await firstFinger.down(center);
    await tester.pump();
    await secondFinger.down(center + const Offset(20, 0));
    await tester.pump();
    await secondFinger.moveTo(center + const Offset(80, 0));
    await tester.pump();
    await secondFinger.up();
    await firstFinger.up();
    await tester.pump();

    await tester.tap(find.byTooltip('保存预览'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    final replayData = (await store.load()).artworks.single.replayData!;
    final strokes = replayData['strokes'] as List<dynamic>;
    final sticker = (strokes.single as Map).cast<String, dynamic>();

    expect(sticker['tool'], 'sticker');
    expect((sticker['width'] as num).toDouble(), greaterThan(10));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'animation theater records three-act stories and rewards premiere',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1133, 744);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = MemoryArtistStore();
      await tester.pumpWidget(LittleArtistVerseApp(store: store));
      await tester.tap(find.text('动画故事'));
      await tester.pumpAndSettle();

      expect(find.text('让你的画演一场故事'), findsOneWidget);
      for (final story in [
        'balloon-adventure',
        'dino-trip',
        'penguin-party',
        'space-pet',
        'ocean-rescue',
        'monster-birthday',
      ]) {
        expect(find.byKey(ValueKey('theater-story-$story')), findsOneWidget);
      }

      await tester.tap(
        find.byKey(const ValueKey('theater-story-balloon-adventure')),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < 3; index++) {
        expect(find.byKey(ValueKey('theater-act-$index')), findsOneWidget);
      }
      for (final background in ['forest', 'sky', 'ocean', 'space', 'castle']) {
        expect(
          find.byKey(ValueKey('theater-background-$background')),
          findsOneWidget,
        );
      }
      for (final action in ['jump', 'blink', 'spin', 'fly', 'magic']) {
        expect(find.byKey(ValueKey('theater-action-$action')), findsOneWidget);
      }

      final record = find.byKey(const ValueKey('theater-record-toggle'));
      await tester.ensureVisible(record);
      await tester.tap(record);
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('theater-stage')),
        const Offset(150, -70),
      );
      await tester.tap(find.byKey(const ValueKey('theater-action-jump')));
      await tester.ensureVisible(record);
      await tester.tap(record);
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('theater-director-panel')),
        const Offset(0, 500),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('theater-act-1')));
      await tester.tap(find.byKey(const ValueKey('theater-background-sky')));
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('theater-director-panel')),
        const Offset(0, -800),
      );
      await tester.pump();
      final premiere = find.byKey(const ValueKey('theater-premiere'));
      await tester.tap(premiere);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('小小电影院'), findsOneWidget);
      expect((await store.load()).preferences['creationStars'], 5);
      expect((await store.load()).preferences['directorPremiereCount'], 1);
      expect(await store.loadDraft('animation-theater-project'), isNotNull);

      for (var index = 0; index < 3; index++) {
        await tester.pump(const Duration(milliseconds: 5100));
      }
      expect(find.text('首映成功！'), findsOneWidget);
      expect(find.text('获得 5 颗小导演星星！'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('theater-back-to-edit')));
      await tester.pump();
      expect(find.text('三幕故事卡'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('animation theater restores a locally saved project', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryArtistStore();
    await store.saveDraft('animation-theater-project', {
      'version': 1,
      'id': 'saved-theater',
      'storyId': 'space-pet',
      'artworkId': 'sun',
      'activeActIndex': 1,
      'acts': [
        for (var index = 0; index < 3; index++)
          {
            'background': index == 1 ? 'space' : 'sky',
            'points': [
              {'milliseconds': 0, 'x': .5, 'y': .56},
              {'milliseconds': 900, 'x': .7, 'y': .4},
            ],
            'cues': <Object?>[],
          },
      ],
    });

    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.tap(find.text('动画故事'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('theater-continue-project')),
      findsOneWidget,
    );
    expect(find.text('太空宠物回家'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('theater-continue-project')));
    await tester.pumpAndSettle();

    expect(find.text('三幕故事卡'), findsOneWidget);
    final spaceChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('theater-background-space')),
    );
    expect(spaceChip.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent gate unlocks statistics and sound controls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.tap(find.text('家长'));
    await tester.pumpAndSettle();
    expect(find.text('12 + 7 等于多少？'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('parent-answer-19')));
    await tester.pumpAndSettle();
    expect(find.text('累计使用'), findsOneWidget);
    expect(find.text('孩子作品'), findsOneWidget);
    expect(find.text('语音提示与音效'), findsOneWidget);
    expect(find.text('推荐年龄'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first use onboarding completes in three steps', (
    WidgetTester tester,
  ) async {
    final store = MemoryArtistStore(
      preferences: {'onboardingComplete': false, 'soundEnabled': false},
    );
    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('欢迎来到小小画室'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    expect(find.text('每次创作都有惊喜'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    expect(find.text('专为孩子安心设计'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.text('今天想做什么？'), findsOneWidget);
    expect((await store.load()).preferences['onboardingComplete'], isTrue);
  });

  testWidgets('coloring playground fills safely and saves to gallery', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.tap(find.text('涂色乐园'));
    await tester.pumpAndSettle();

    expect(find.text('彩虹蝴蝶'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('coloring-template-fish')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('coloring-template-rabbit')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('coloring-template-pony')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('coloring-template-penguin')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('coloring-template-rabbit')));
    await tester.pump();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('coloring-canvas'))),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('coloring-save')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('太棒啦！'), findsOneWidget);
    expect(find.textContaining('获得一颗创作星星'), findsOneWidget);
    await tester.tap(find.text('继续创作'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('作品集'));
    await tester.pumpAndSettle();
    expect(find.text('涂色作品 · 软萌小兔'), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    expect(find.text('涂色作品 · 软萌小兔'), findsOneWidget);
    expect(find.text('⭐ 1 · 🔥 1 天'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'daily challenge offers a creative mission and rewards completion',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1133, 744);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryArtistStore();

      await tester.pumpWidget(LittleArtistVerseApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('daily-challenge-home')));
      await tester.pumpAndSettle();

      expect(find.text('今日创意任务'), findsOneWidget);
      expect(find.text('神奇任务卡'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('daily-challenge-canvas')),
        findsOneWidget,
      );
      expect(find.byTooltip('印章'), findsOneWidget);
      expect(find.byTooltip('贴纸'), findsOneWidget);

      await pinchZoom(
        tester,
        find.byKey(const ValueKey('daily-challenge-canvas')),
      );
      expect(
        find.byKey(const ValueKey('daily-challenge-reset-view')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('daily-challenge-reset-view')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('daily-challenge-reset-view')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('challenge-shuffle-task')));
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('daily-challenge-canvas')),
        const Offset(95, 55),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('challenge-finish')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();

      expect(find.text('挑战完成！'), findsOneWidget);
      expect(find.text('作品已保存，获得 3 颗创意星星！'), findsOneWidget);
      final snapshot = await store.load();
      expect(snapshot.artworks.single.source, 'challenge');
      expect(snapshot.artworks.single.replayData?['challengeId'], isNotNull);
      expect(snapshot.preferences['challengeCount'], 1);
      expect(snapshot.preferences['creationStars'], 3);

      await tester.tap(find.text('返回首页'));
      await tester.pumpAndSettle();
      expect(find.text('今天已完成，明天再来'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('lesson catalog stays usable on a short landscape phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryArtistStore();
    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.ensureVisible(find.text('跟着学画'));
    await tester.tap(find.text('跟着学画'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('跟着学画'), findsOneWidget);
    expect(find.byKey(const ValueKey('lesson-continue')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery filters favorites and opens artwork details', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
    await tester.tap(find.text('我的作品集'));
    await tester.pumpAndSettle();

    expect(find.text('米娅的小画展'), findsOneWidget);
    expect(find.text('4 幅作品'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('gallery-card-sun')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('gallery-favorite-sun')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gallery-filter-收藏')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('gallery-card-sun')), findsOneWidget);
    expect(find.text('1 幅作品'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gallery-card-sun')));
    await tester.pumpAndSettle();
    expect(find.text('作品详情 · 开心的太阳'), findsOneWidget);
    expect(find.text('每一次创作都值得被好好收藏。给喜欢的作品点一颗爱心吧！'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawing save appears in gallery and can be renamed or deleted', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryArtistStore();
    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('free-drawing-canvas')),
      const Offset(90, 45),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('保存预览'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    final savedArtwork = (await store.load()).artworks.single;
    expect(savedArtwork.replayData?['strokes'], isNotEmpty);
    expect(savedArtwork.replayData?['canvasWidth'], isA<num>());

    await tester.tap(find.text('作品集'));
    await tester.pumpAndSettle();
    expect(find.text('我的画作 1'), findsOneWidget);
    expect(find.text('5 幅作品'), findsNWidgets(2));

    await tester.tap(find.text('我的画作 1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gallery-rename')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gallery-rename')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('gallery-rename-field')),
      '彩虹花园',
    );
    await tester.tap(find.text('保存名字'));
    await tester.pumpAndSettle();
    expect(find.text('作品详情 · 彩虹花园'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gallery-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(find.text('4 幅作品'), findsNWidgets(2));
    expect(find.text('彩虹花园'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved free artwork can be edited and saved as a copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1133, 744);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryArtistStore();
    await tester.pumpWidget(LittleArtistVerseApp(store: store));
    await tester.tap(find.text('自由画画'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('free-drawing-canvas')),
      const Offset(90, 45),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('保存预览'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect((await store.load()).artworks, hasLength(1));

    await tester.tap(find.text('作品集'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的画作 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gallery-continue-edit')));
    await tester.pumpAndSettle();

    expect(find.text('继续画「我的画作 1」'), findsOneWidget);
    expect(find.byTooltip('更新原作品'), findsOneWidget);
    expect(find.byTooltip('另存一份'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('free-drawing-canvas')),
      const Offset(-60, 55),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('更新原作品'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect((await store.load()).artworks, hasLength(1));

    await tester.tap(find.byTooltip('另存一份'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect((await store.load()).artworks, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
