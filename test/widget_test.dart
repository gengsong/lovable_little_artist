import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/local_artist_store.dart';
import 'package:lovable_little_artist/main.dart';

void main() {
  testWidgets('shows Lovable-inspired home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));

    expect(find.text('米娅!'), findsOneWidget);
    expect(find.text('今天想做什么？'), findsOneWidget);
    expect(find.text('自由画画'), findsOneWidget);
    expect(find.text('跟着学画'), findsOneWidget);
    expect(find.text('最近画的'), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('lesson-card-round-cat')));
    await tester.pumpAndSettle();

    expect(find.text('第 1 / 4 步'), findsOneWidget);
    expect(find.text('画一个大圆'), findsOneWidget);

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

    await tester.tap(find.byKey(const ValueKey('lesson-card-round-cat')));
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

  testWidgets('lesson catalog stays usable on a short landscape phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
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

    await tester.pumpWidget(LittleArtistVerseApp(store: MemoryArtistStore()));
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
}
