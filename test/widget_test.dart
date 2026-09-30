import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hg_app/core/app/hg_app.dart';
import 'package:hg_app/features/player/application/player_controller.dart';

void main() {
  Future<void> pumpHgApp(
    WidgetTester tester, {
    Size size = const Size(390, 867),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [videoPlaybackEnabledProvider.overrideWithValue(false)],
        child: const HgApp(),
      ),
    );
    await tester.pump();
  }

  void expectInViewport(WidgetTester tester, Finder finder, Size size) {
    final topLeft = tester.getTopLeft(finder);
    final bottomRight = tester.getBottomRight(finder);

    expect(topLeft.dx, greaterThanOrEqualTo(0));
    expect(topLeft.dy, greaterThanOrEqualTo(0));
    expect(bottomRight.dx, lessThanOrEqualTo(size.width));
    expect(bottomRight.dy, lessThanOrEqualTo(size.height));
  }

  Rect widgetRect(WidgetTester tester, Key key) {
    return tester.getRect(find.byKey(key));
  }

  testWidgets('shows the drama player MVP surface', (tester) async {
    await pumpHgApp(tester);

    expect(find.text('关注'), findsOneWidget);
    expect(find.text('漫剧'), findsOneWidget);
    expect(find.text('真人剧'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('11:26'), findsNothing);
    expect(find.text('5G'), findsNothing);
    expect(find.text('标签造神第一季海大篇 ›'), findsOneWidget);
    expect(find.text('3D'), findsOneWidget);
    expect(find.text('系统'), findsOneWidget);
    expect(find.text('观看完整漫剧 · 全316集'), findsOneWidget);
    expect(find.byKey(const Key('fullscreen-episode-001')), findsOneWidget);
    expect(
      tester
          .widget<SvgPicture>(
            find.byKey(const Key('fullscreen-orientation-icon')),
          )
          .bytesLoader
          .toString(),
      'SvgAssetLoader(lib/icons/orientation_switch.svg)',
    );
    expect(find.byKey(const Key('like-episode-001')), findsOneWidget);
    expect(find.byKey(const Key('favorite-episode-001')), findsOneWidget);
  });

  testWidgets('updates like and favorite states immediately', (tester) async {
    await pumpHgApp(tester);

    SvgPicture railIcon(String key) {
      return tester.widget<SvgPicture>(find.byKey(Key(key)));
    }

    expect(
      railIcon('favorite-icon-episode-001').bytesLoader.toString(),
      'SvgAssetLoader(lib/icons/favorite_star.svg)',
    );
    expect(
      railIcon('comment-icon-episode-001').bytesLoader.toString(),
      'SvgAssetLoader(lib/icons/comment_bubble.svg)',
    );
    expect(
      railIcon('like-icon-episode-001').bytesLoader.toString(),
      'SvgAssetLoader(lib/icons/heart_like.svg)',
    );
    expect(
      railIcon('share-icon-episode-001').bytesLoader.toString(),
      'SvgAssetLoader(lib/icons/share_arrow.svg)',
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HgApp)),
      listen: false,
    );
    expect(
      container.read(playerControllerProvider).isLiked('episode-001'),
      false,
    );
    expect(
      container.read(playerControllerProvider).isFavorited('episode-001'),
      false,
    );

    await tester.tap(find.byKey(const Key('like-episode-001')));
    await tester.tap(find.byKey(const Key('favorite-episode-001')));
    await tester.pump();

    expect(
      container.read(playerControllerProvider).isLiked('episode-001'),
      true,
    );
    expect(
      container.read(playerControllerProvider).isFavorited('episode-001'),
      true,
    );
  });

  testWidgets('toggles playback only when tapping the video layer', (
    tester,
  ) async {
    await pumpHgApp(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HgApp)),
      listen: false,
    );

    expect(container.read(playerControllerProvider).isPlaying, true);

    await tester.tap(find.byKey(const Key('like-episode-001')));
    await tester.pump();

    expect(container.read(playerControllerProvider).isPlaying, true);
    expect(
      container.read(playerControllerProvider).isLiked('episode-001'),
      true,
    );

    await tester.tap(find.byKey(const Key('video-tap-layer-episode-001')));
    await tester.pump();

    expect(container.read(playerControllerProvider).isPlaying, false);

    await tester.tap(find.byKey(const Key('favorite-episode-001')));
    await tester.pump();

    expect(container.read(playerControllerProvider).isPlaying, false);
    expect(
      container.read(playerControllerProvider).isFavorited('episode-001'),
      true,
    );

    await tester.tap(find.byKey(const Key('video-tap-layer-episode-001')));
    await tester.pump();

    expect(container.read(playerControllerProvider).isPlaying, true);
  });

  testWidgets('switches drama card on vertical swipe', (tester) async {
    await pumpHgApp(tester);

    expect(find.text('标签造神第一季海大篇 ›'), findsOneWidget);
    final recommendedPosition = tester.getTopLeft(find.text('推荐'));
    final homePosition = tester.getTopLeft(find.text('首页'));

    await tester.drag(
      find.byKey(const Key('player-feed-page-view')),
      const Offset(0, -720),
    );
    await tester.pumpAndSettle();

    expect(find.text('重生后我在都市开挂 ›'), findsOneWidget);
    expect(find.byKey(const Key('fullscreen-episode-002')), findsNothing);
    expect(tester.getTopLeft(find.text('推荐')), recommendedPosition);
    expect(tester.getTopLeft(find.text('首页')), homePosition);
  });

  testWidgets('keeps product chrome visible on common phone sizes', (
    tester,
  ) async {
    const sizes = [
      Size(375, 667),
      Size(360, 640),
      Size(390, 867),
      Size(430, 932),
    ];

    for (final size in sizes) {
      await pumpHgApp(tester, size: size);

      expectInViewport(tester, find.text('推荐'), size);
      expectInViewport(tester, find.text('首页'), size);
      expectInViewport(tester, find.text('观看完整漫剧 · 全316集'), size);
      expectInViewport(tester, find.byKey(const Key('like-episode-001')), size);

      final mediaRect = widgetRect(
        tester,
        const Key('media-panel-episode-001'),
      );
      final fullscreenRect = widgetRect(
        tester,
        const Key('fullscreen-episode-001'),
      );
      final infoRect = widgetRect(tester, const Key('info-panel-episode-001'));
      final seriesPillRect = widgetRect(
        tester,
        const Key('series-pill-episode-001'),
      );
      final leftStackRect = widgetRect(
        tester,
        const Key('left-info-stack-episode-001'),
      );
      final barrageRect = widgetRect(
        tester,
        const Key('barrage-button-episode-001'),
      );
      final railRect = widgetRect(tester, const Key('action-rail-episode-001'));
      final completeRect = widgetRect(
        tester,
        const Key('complete-entry-episode-001'),
      );
      final channelBar = tester.widget<Container>(
        find.byKey(const Key('channel-bar')),
      );
      final completeSurface = tester.widget<Container>(
        find.byKey(const Key('complete-entry-surface-episode-001')),
      );
      final recommendedPosition = tester.getTopLeft(find.text('推荐'));
      final homePosition = tester.getTopLeft(find.text('首页'));
      final landscapeCenterY = (size.height - 68) / 2;
      final bottomContentGap = size.height < 720 ? 8.0 : 14.0;
      final barrageInfoGap = size.height < 720 ? 8.0 : 12.0;

      expect(channelBar.color, Colors.transparent);
      expect(completeSurface.color, const Color(0xCC242424));
      expect(mediaRect.left, closeTo(0, 1));
      expect(mediaRect.width, closeTo(size.width, 1));
      expect(mediaRect.width / mediaRect.height, closeTo(16 / 9, 0.01));
      expect(mediaRect.center.dy, closeTo(landscapeCenterY, 1));
      expect(
        fullscreenRect.top - mediaRect.bottom,
        inInclusiveRange(6.0, 16.0),
      );
      expect(seriesPillRect.width, lessThan(infoRect.width));
      expect(seriesPillRect.width, lessThanOrEqualTo(infoRect.width));
      expect(infoRect.top - barrageRect.bottom, closeTo(barrageInfoGap, 1));
      expect(leftStackRect.bottom, closeTo(infoRect.bottom, 1));
      expect(infoRect.bottom, closeTo(completeRect.top - bottomContentGap, 1));
      expect(railRect.bottom, closeTo(leftStackRect.bottom, 1));
      expect(completeRect.bottom, lessThan(homePosition.dy));
      if (size.height < 670) {
        expect(find.text('作者声明： 内容由AI生成'), findsNothing);
      }

      await tester.drag(
        find.byKey(const Key('player-feed-page-view')),
        Offset(0, -size.height * 0.78),
      );
      await tester.pumpAndSettle();

      expect(find.text('重生后我在都市开挂 ›'), findsOneWidget);
      expect(find.byKey(const Key('fullscreen-episode-002')), findsNothing);
      final portraitMediaRect = widgetRect(
        tester,
        const Key('media-panel-episode-002'),
      );
      final portraitInfoRect = widgetRect(
        tester,
        const Key('info-panel-episode-002'),
      );
      final recommendedBottom = tester.getBottomLeft(find.text('推荐')).dy;

      expect(portraitMediaRect.left, closeTo(0, 1));
      expect(portraitMediaRect.width, closeTo(size.width, 1));
      expect(portraitMediaRect.height, greaterThan(portraitMediaRect.width));
      expect(
        portraitMediaRect.height / portraitMediaRect.width,
        closeTo(1280 / 720, 0.01),
      );
      expect(portraitMediaRect.top, closeTo(0, 1));
      expect(portraitMediaRect.top, lessThan(recommendedBottom));
      expect(portraitMediaRect.bottom, greaterThan(portraitInfoRect.top));
      expect(tester.getTopLeft(find.text('推荐')), recommendedPosition);
      expect(tester.getTopLeft(find.text('首页')), homePosition);
    }
  });

  testWidgets('renders series pill as static intrinsic-width text', (
    tester,
  ) async {
    await pumpHgApp(tester);

    final infoRect = widgetRect(tester, const Key('info-panel-episode-001'));
    final seriesPillRect = widgetRect(
      tester,
      const Key('series-pill-episode-001'),
    );
    final seriesPill = tester.widget<DecoratedBox>(
      find.byKey(const Key('series-pill-episode-001')),
    );
    final iconBackground = tester.widget<Container>(
      find.byKey(const Key('series-pill-icon-episode-001')),
    );
    final decoration = seriesPill.decoration as BoxDecoration;
    final iconDecoration = iconBackground.decoration! as BoxDecoration;

    expect(seriesPillRect.width, lessThan(infoRect.width));
    expect(seriesPillRect.width, lessThanOrEqualTo(infoRect.width));
    expect(decoration.border, isNull);
    expect(iconDecoration.color, Colors.white);
    expect(find.byKey(const Key('track-drama-tag-god')), findsNothing);
    expect(find.textContaining('已追剧'), findsNothing);

    await tester.tap(find.byKey(const Key('series-pill-episode-001')));
    await tester.pump();

    expect(find.text('系列剧 · 标签造神 | 共236万人在追'), findsOneWidget);
    expect(find.textContaining('已追剧'), findsNothing);
    expect(
      (tester
                  .widget<DecoratedBox>(
                    find.byKey(const Key('series-pill-episode-001')),
                  )
                  .decoration
              as BoxDecoration)
          .border,
      isNull,
    );
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const Key('series-pill-icon-episode-001')),
                  )
                  .decoration!
              as BoxDecoration)
          .color,
      Colors.white,
    );
  });

  testWidgets('keeps page-owned bottom content aligned after page switch', (
    tester,
  ) async {
    await pumpHgApp(tester);

    final recommendedPosition = tester.getTopLeft(find.text('推荐'));
    final homePosition = tester.getTopLeft(find.text('首页'));
    final firstCompleteRect = widgetRect(
      tester,
      const Key('complete-entry-episode-001'),
    );
    final firstInfoRect = widgetRect(
      tester,
      const Key('info-panel-episode-001'),
    );
    final firstRailRect = widgetRect(
      tester,
      const Key('action-rail-episode-001'),
    );

    await tester.drag(
      find.byKey(const Key('player-feed-page-view')),
      const Offset(0, -720),
    );
    await tester.pumpAndSettle();

    expect(
      widgetRect(tester, const Key('complete-entry-episode-002')).top,
      closeTo(firstCompleteRect.top, 1),
    );
    expect(
      widgetRect(tester, const Key('info-panel-episode-002')).bottom,
      closeTo(firstInfoRect.bottom, 1),
    );
    expect(
      widgetRect(tester, const Key('action-rail-episode-002')).bottom,
      closeTo(firstRailRect.bottom, 1),
    );
    expect(tester.getTopLeft(find.text('推荐')), recommendedPosition);
    expect(tester.getTopLeft(find.text('首页')), homePosition);
  });
}
