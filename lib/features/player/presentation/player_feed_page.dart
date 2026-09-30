import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../application/player_controller.dart';
import '../data/player_feed_repository.dart';
import '../domain/drama_episode.dart';
import 'widgets/drama_video_player.dart';

class PlayerFeedPage extends ConsumerStatefulWidget {
  const PlayerFeedPage({super.key});

  @override
  ConsumerState<PlayerFeedPage> createState() => _PlayerFeedPageState();
}

class _PlayerFeedPageState extends ConsumerState<PlayerFeedPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final episodes = ref.watch(playerFeedProvider);
    final state = ref.watch(playerControllerProvider);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = PlayerLayoutMetrics.from(
            size: constraints.biggest,
            padding: mediaQuery.padding,
          );

          return Stack(
            children: [
              PageView.builder(
                key: const Key('player-feed-page-view'),
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: episodes.length,
                onPageChanged: (index) {
                  ref
                      .read(playerControllerProvider.notifier)
                      .setCurrentIndex(index);
                },
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  final distance = (index - state.currentIndex).abs();

                  return EpisodePage(
                    key: ValueKey(episode.id),
                    episode: episode,
                    metrics: metrics,
                    isActive: index == state.currentIndex,
                    shouldPrepareVideo: distance <= 1,
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: metrics.topChromeHeight,
                child: PlayerChannelBar(metrics: metrics),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: metrics.bottomChromeHeight,
                child: PlayerBottomNav(metrics: metrics),
              ),
            ],
          );
        },
      ),
    );
  }
}

@immutable
class PlayerLayoutMetrics {
  const PlayerLayoutMetrics({required this.size, required this.padding});

  factory PlayerLayoutMetrics.from({
    required Size size,
    required EdgeInsets padding,
  }) {
    return PlayerLayoutMetrics(size: size, padding: padding);
  }

  static const double channelBarHeight = 58;
  static const double bottomNavHeight = 68;
  static const double completeEntryHeight = 58;

  final Size size;
  final EdgeInsets padding;

  double get topChromeHeight => padding.top + channelBarHeight;

  double get bottomChromeHeight => padding.bottom + bottomNavHeight;

  double get contentTop => topChromeHeight;

  double get contentBottom =>
      math.max(contentTop, size.height - bottomChromeHeight);

  double get contentHeight => math.max(0, contentBottom - contentTop);

  double get completeEntryTop =>
      math.max(contentTop, contentBottom - completeEntryHeight);

  double get horizontalPadding => size.width <= 370 ? 16 : 18;

  bool get isCompactHeight => size.height < 720 || contentHeight < 560;

  bool get isVeryCompactHeight => size.height < 670 || contentHeight < 510;
}

class EpisodePage extends ConsumerWidget {
  const EpisodePage({
    super.key,
    required this.episode,
    required this.metrics,
    required this.isActive,
    required this.shouldPrepareVideo,
  });

  final DramaEpisode episode;
  final PlayerLayoutMetrics metrics;
  final bool isActive;
  final bool shouldPrepareVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(playerControllerProvider);
    final notifier = ref.read(playerControllerProvider.notifier);
    final videoEnabled = ref.watch(videoPlaybackEnabledProvider);
    final isLiked = controllerState.isLiked(episode.id);
    final isFavorited = controllerState.isFavorited(episode.id);
    final shouldPlay = isActive && controllerState.isPlaying;
    final layout = _EpisodeLayout(metrics, episode.videoResolution);

    return MediaQuery.withNoTextScaling(
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: layout.mediaLeft,
              width: layout.mediaWidth,
              top: layout.mediaTop,
              height: layout.mediaHeight,
              child: EpisodeMediaPanel(
                key: Key('media-panel-${episode.id}'),
                episode: episode,
                isPlaying: shouldPlay,
                enableController: videoEnabled && shouldPrepareVideo,
                onTogglePlay: notifier.togglePlayPause,
                tapLayerKey: Key('video-tap-layer-${episode.id}'),
              ),
            ),
            Positioned(
              right: 6,
              bottom: layout.bottomInfoBottomInset,
              width: 64,
              child: EpisodeActionRail(
                key: Key('action-rail-${episode.id}'),
                episode: episode,
                isLiked: isLiked,
                isFavorited: isFavorited,
                favoriteCount: controllerState.favoriteCountFor(episode),
                likeCount: controllerState.likeCountFor(episode),
                compact: metrics.isCompactHeight,
                onFavorite: () => notifier.toggleFavorite(episode.id),
                onComment: () => _showMessage(context, '评论功能即将开放'),
                onLike: () => notifier.toggleLike(episode.id),
                onShare: () => _showMessage(context, '分享链接已准备好'),
              ),
            ),
            if (layout.showFullscreen)
              Positioned(
                left: 0,
                right: 0,
                top: layout.fullscreenTop,
                child: Center(
                  child: _FullscreenButton(
                    key: Key('fullscreen-${episode.id}'),
                    onTap: () => _showMessage(context, '全屏观看即将开放'),
                  ),
                ),
              ),
            Positioned(
              left: metrics.horizontalPadding,
              right: layout.infoRightInset,
              bottom: layout.bottomInfoBottomInset,
              child: EpisodeLeftInfoStack(
                key: Key('left-info-stack-${episode.id}'),
                episode: episode,
                compact: metrics.isCompactHeight,
                veryCompact: metrics.isVeryCompactHeight,
                gap: layout.barrageInfoGap,
                onBarrage: () => _showMessage(context, '弹幕开关已切换'),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: metrics.completeEntryTop,
              height: PlayerLayoutMetrics.completeEntryHeight,
              child: CompleteDramaEntry(
                key: Key('complete-entry-${episode.id}'),
                episode: episode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EpisodeLayout {
  _EpisodeLayout(this.metrics, this.resolution);

  final PlayerLayoutMetrics metrics;
  final VideoResolution resolution;

  bool get showFullscreen => resolution.isLandscape;

  double get mediaWidth => mediaSize.width;

  double get mediaHeight => mediaSize.height;

  Size get mediaSize {
    final width = metrics.size.width;
    return Size(width, width / resolution.aspectRatio);
  }

  double get mediaLeft => 0;

  double get landscapeCenterY =>
      (metrics.size.height - metrics.bottomChromeHeight) / 2;

  double get mediaTop {
    if (resolution.isPortrait) {
      return 0;
    }

    return math.max(0, landscapeCenterY - mediaHeight / 2);
  }

  double get mediaBottom => mediaTop + mediaHeight;

  double get fullscreenTop => mediaBottom + fullscreenGap;

  double get captionTop {
    final preferredTop = mediaBottom - 34;
    if (showFullscreen) {
      return preferredTop;
    }

    return math.max(mediaTop, math.min(preferredTop, infoTop - 46));
  }

  double get fullscreenGap => metrics.isCompactHeight ? 8 : 14;

  double get barrageInfoGap => metrics.isCompactHeight ? 8 : 12;

  double get bottomContentGap => metrics.isCompactHeight ? 8 : 14;

  double get bottomInfoBottomInset =>
      metrics.bottomChromeHeight +
      PlayerLayoutMetrics.completeEntryHeight +
      bottomContentGap;

  double get bottomInfoBottom => metrics.size.height - bottomInfoBottomInset;

  double get estimatedInfoHeight {
    if (metrics.isVeryCompactHeight) {
      return 97;
    }
    return metrics.isCompactHeight ? 126 : 167;
  }

  double get infoTop {
    return math.max(
      metrics.contentTop + 16,
      bottomInfoBottom - estimatedInfoHeight,
    );
  }

  double get infoRightInset => metrics.size.width < 390 ? 84 : 96;
}

class PlayerChannelBar extends StatelessWidget {
  const PlayerChannelBar({super.key, required this.metrics});

  final PlayerLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Container(
        key: const Key('channel-bar'),
        color: Colors.transparent,
        padding: EdgeInsets.only(top: metrics.padding.top),
        child: SizedBox(
          height: PlayerLayoutMetrics.channelBarHeight,
          child: Row(
            children: [
              const SizedBox(width: 20),
              const Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ChannelTab('关注'),
                    SizedBox(width: 22),
                    _ChannelTab('漫剧'),
                    SizedBox(width: 22),
                    _ChannelTab('真人剧'),
                    SizedBox(width: 22),
                    _ChannelTab('推荐', selected: true),
                  ],
                ),
              ),
              const SizedBox(
                width: 50,
                child: Icon(Icons.search, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelTab extends StatelessWidget {
  const _ChannelTab(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AppText(
            label,
            size: 20,
            weight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFFA8A8A8),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: selected ? 29 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerBottomNav extends StatelessWidget {
  const PlayerBottomNav({super.key, required this.metrics});

  final PlayerLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Container(
        color: const Color(0xFF222222),
        padding: EdgeInsets.only(bottom: metrics.padding.bottom),
        child: const SizedBox(
          height: PlayerLayoutMetrics.bottomNavHeight,
          child: Stack(
            children: [
              Row(
                children: [
                  _BottomNavItem(label: '首页', selected: true),
                  _BottomNavItem(label: '剧场'),
                  _BottomNavItem(label: '商城', muted: true),
                  _BottomNavItem(label: '赚钱', muted: true),
                  _BottomNavItem(label: '我的', muted: true),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 4,
                child: Row(
                  children: [
                    Spacer(flex: 3),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _EarnBadge(),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
              Positioned(
                right: 21,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B00),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 7, height: 7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    this.selected = false,
    this.muted = false,
  });

  final String label;
  final bool selected;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : muted
        ? const Color(0xFF747474)
        : const Color(0xFF878787);

    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 11),
          child: _AppText(
            label,
            size: 17,
            weight: selected ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _EarnBadge extends StatelessWidget {
  const _EarnBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 19,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const _AppText('赚钱', size: 10, weight: FontWeight.w800),
    );
  }
}

class EpisodeMediaPanel extends StatelessWidget {
  const EpisodeMediaPanel({
    super.key,
    required this.episode,
    required this.isPlaying,
    required this.enableController,
    required this.onTogglePlay,
    this.tapLayerKey,
  });

  final DramaEpisode episode;
  final bool isPlaying;
  final bool enableController;
  final VoidCallback onTogglePlay;
  final Key? tapLayerKey;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DramaVideoPlayer(
        assetPath: episode.videoAssetPath,
        resolution: episode.videoResolution,
        isPlaying: isPlaying,
        enableController: enableController,
        onTogglePlay: onTogglePlay,
        tapLayerKey: tapLayerKey,
      ),
    );
  }
}

class EpisodeActionRail extends StatelessWidget {
  const EpisodeActionRail({
    super.key,
    required this.episode,
    required this.isLiked,
    required this.isFavorited,
    required this.favoriteCount,
    required this.likeCount,
    required this.compact,
    required this.onFavorite,
    required this.onComment,
    required this.onLike,
    required this.onShare,
  });

  final DramaEpisode episode;
  final bool isLiked;
  final bool isFavorited;
  final int favoriteCount;
  final int likeCount;
  final bool compact;
  final VoidCallback onFavorite;
  final VoidCallback onComment;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 10.0 : 18.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailAction(
          key: Key('favorite-${episode.id}'),
          iconAsset: 'lib/icons/favorite_star.svg',
          iconKey: Key('favorite-icon-${episode.id}'),
          label: _formatCount(favoriteCount),
          selected: isFavorited,
          compact: compact,
          onTap: onFavorite,
        ),
        SizedBox(height: gap),
        _RailAction(
          key: Key('comment-${episode.id}'),
          iconAsset: 'lib/icons/comment_bubble.svg',
          iconKey: Key('comment-icon-${episode.id}'),
          label: episode.stats.commentCount.toString(),
          compact: compact,
          onTap: onComment,
        ),
        SizedBox(height: gap),
        _RailAction(
          key: Key('like-${episode.id}'),
          iconAsset: 'lib/icons/heart_like.svg',
          iconKey: Key('like-icon-${episode.id}'),
          label: _formatCount(likeCount),
          selected: isLiked,
          compact: compact,
          inactiveLabelColor: const Color(0xFFBDBDBD),
          onTap: onLike,
        ),
        SizedBox(height: gap),
        _RailAction(
          key: Key('share-${episode.id}'),
          iconAsset: 'lib/icons/share_arrow.svg',
          iconKey: Key('share-icon-${episode.id}'),
          label: '分享',
          compact: compact,
          inactiveLabelColor: const Color(0xFFBDBDBD),
          onTap: onShare,
        ),
      ],
    );
  }
}

class _RailAction extends StatelessWidget {
  const _RailAction({
    super.key,
    required this.iconAsset,
    required this.iconKey,
    required this.label,
    required this.onTap,
    required this.compact,
    this.selected = false,
    this.inactiveLabelColor = Colors.white,
  });

  final String iconAsset;
  final Key iconKey;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool selected;
  final Color inactiveLabelColor;

  @override
  Widget build(BuildContext context) {
    final activeColor = selected ? const Color(0xFFFF7A00) : Colors.white;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: compact ? 55 : 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                iconAsset,
                key: iconKey,
                width: compact ? 34 : 40,
                height: compact ? 34 : 40,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                colorFilter: ColorFilter.mode(activeColor, BlendMode.srcIn),
              ),
              SizedBox(height: compact ? 3 : 4),
              _AppText(
                label,
                size: compact ? 13 : 15,
                weight: FontWeight.w700,
                color: selected ? activeColor : inactiveLabelColor,
                lineHeight: 1,
                fontFamily: 'Inter',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarrageButton extends StatelessWidget {
  const _BarrageButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const _AppText('弹/', size: 13, weight: FontWeight.w800),
      ),
    );
  }
}

class EpisodeLeftInfoStack extends StatelessWidget {
  const EpisodeLeftInfoStack({
    super.key,
    required this.episode,
    required this.compact,
    required this.veryCompact,
    required this.gap,
    required this.onBarrage,
  });

  final DramaEpisode episode;
  final bool compact;
  final bool veryCompact;
  final double gap;
  final VoidCallback onBarrage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BarrageButton(
          key: Key('barrage-button-${episode.id}'),
          onTap: onBarrage,
        ),
        SizedBox(height: gap),
        SizedBox(
          width: double.infinity,
          child: EpisodeInfoPanel(
            key: Key('info-panel-${episode.id}'),
            episode: episode,
            compact: compact,
            gap: gap,
            veryCompact: veryCompact,
          ),
        ),
      ],
    );
  }
}

class _FullscreenButton extends StatelessWidget {
  const _FullscreenButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D1D),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'lib/icons/orientation_switch.svg',
              key: const Key('fullscreen-orientation-icon'),
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            const _AppText('全屏观看', size: 12, weight: FontWeight.w700),
          ],
        ),
      ),
    );
  }
}

class EpisodeInfoPanel extends StatelessWidget {
  const EpisodeInfoPanel({
    super.key,
    required this.episode,
    required this.compact,
    required this.veryCompact,
    required this.gap,
  });

  final DramaEpisode episode;
  final bool compact;
  final bool veryCompact;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SeriesPill(episode: episode),
        SizedBox(height: gap),
        _AppText(
          '${episode.title} ›',
          key: Key('episode-title-${episode.id}'),
          size: compact ? 17 : 18,
          weight: FontWeight.w800,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: gap),
        _TagRow(tags: episode.tags.take(compact ? 4 : 5).toList()),
        if (!veryCompact) ...[
          SizedBox(height: gap),
          _HotComment(commentPreview: episode.commentPreview),
          if (!compact) ...[SizedBox(height: gap), const _AuthorDisclosure()],
        ],
      ],
    );
  }
}

class _SeriesPill extends StatelessWidget {
  const _SeriesPill({required this.episode});

  final DramaEpisode episode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 280.0;
        final maxWidth = math.max(0.0, availableWidth - 12);
        const horizontalPadding = 24.0;
        const iconWidth = 16.0;
        const iconGap = 6.0;
        final textStyle = const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          fontFamily: 'Noto Sans SC',
        );
        final textPainter = TextPainter(
          text: TextSpan(text: episode.followerText, style: textStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();
        final desiredWidth =
            horizontalPadding + iconWidth + iconGap + textPainter.width;
        final pillWidth = math.min(desiredWidth, maxWidth);
        final maxTextWidth = math.max(
          0.0,
          pillWidth - horizontalPadding - iconWidth - iconGap,
        );

        return SizedBox(
          width: pillWidth,
          child: DecoratedBox(
            key: Key('series-pill-${episode.id}'),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    key: Key('series-pill-icon-${episode.id}'),
                    width: 16,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 13,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: maxTextWidth,
                    child: _AppText(
                      episode.followerText,
                      size: 12,
                      weight: FontWeight.w700,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var index = 0; index < tags.length; index++) ...[
              if (index > 0) const SizedBox(width: 5),
              _TagChip(tags[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(child: _AppText(label, size: 12, weight: FontWeight.w700)),
    );
  }
}

class _HotComment extends StatelessWidget {
  const _HotComment({required this.commentPreview});

  final String commentPreview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.local_fire_department, color: Colors.white, size: 17),
        const SizedBox(width: 5),
        const _AppText('热评：', size: 14, weight: FontWeight.w700),
        Expanded(
          child: _AppText(
            commentPreview,
            size: 14,
            weight: FontWeight.w500,
            color: Color(0xFF9B9B9B),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        const _AppText('展开', size: 14, weight: FontWeight.w700),
      ],
    );
  }
}

class _AuthorDisclosure extends StatelessWidget {
  const _AuthorDisclosure();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, color: Color(0xFF666666), size: 15),
        SizedBox(width: 6),
        _AppText(
          '作者声明： 内容由AI生成',
          size: 12,
          weight: FontWeight.w500,
          color: Color(0xFF626262),
        ),
      ],
    );
  }
}

class CompleteDramaEntry extends StatelessWidget {
  const CompleteDramaEntry({super.key, required this.episode});

  final DramaEpisode episode;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('complete-entry-surface-${episode.id}'),
      color: const Color(0xCC242424),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AppText(
                    '观看完整漫剧 · 全${episode.episodeCount}集',
                    size: 15,
                    weight: FontWeight.w800,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              ],
            ),
          ),
          SizedBox(
            height: 10,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C3C3C),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: episode.progress.clamp(0, 1),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(
                    -1 + 2 * episode.progress.clamp(0, 1),
                    0,
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppText extends StatelessWidget {
  const _AppText(
    this.text, {
    super.key,
    required this.size,
    this.weight = FontWeight.w600,
    this.color = Colors.white,
    this.lineHeight,
    this.fontFamily = 'Noto Sans SC',
    this.overflow = TextOverflow.clip,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double? lineHeight;
  final String fontFamily;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: lineHeight,
        letterSpacing: 0,
        fontFamily: fontFamily,
      ),
    );
  }
}

String _formatCount(int value) {
  if (value >= 10000) {
    final wan = value / 10000;
    final text = wan >= 100 ? wan.toStringAsFixed(1) : wan.toStringAsFixed(1);
    return '${text.replaceAll(RegExp(r'\.0$'), '')}万';
  }
  return value.toString();
}
