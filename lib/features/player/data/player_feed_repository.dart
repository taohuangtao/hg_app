import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/drama_episode.dart';

abstract class PlayerFeedRepository {
  List<DramaEpisode> fetchRecommendedEpisodes();
}

final playerFeedRepositoryProvider = Provider<PlayerFeedRepository>(
  (ref) => const MockPlayerFeedRepository(),
);

final playerFeedProvider = Provider<List<DramaEpisode>>((ref) {
  return ref.watch(playerFeedRepositoryProvider).fetchRecommendedEpisodes();
});

class MockPlayerFeedRepository implements PlayerFeedRepository {
  const MockPlayerFeedRepository();

  static const _tagGodVideoAssetPath = '_video/1111.mp4';
  static const _cityRebornVideoAssetPath = '_video/20260630-145038.mp4';
  static const _systemOnlineVideoAssetPath = '_video/MiniMax_H3_00001_.mp4';

  @override
  List<DramaEpisode> fetchRecommendedEpisodes() {
    return const [
      DramaEpisode(
        id: 'episode-001',
        dramaId: 'drama-tag-god',
        title: '标签造神第一季海大篇',
        seasonLabel: '第1季',
        tags: ['3D', '第1季', '都市', '系统', '脑洞'],
        episodeCount: 316,
        videoAssetPath: _tagGodVideoAssetPath,
        videoResolution: VideoResolution(width: 640, height: 360),
        progress: 0.25,
        stats: EpisodeStats(
          favoriteCount: 1858000,
          commentCount: 1141,
          likeCount: 92000,
        ),
        commentPreview: '缘分始于悠闲，最终...',
        followerText: '系列剧 · 标签造神 | 共236万人在追',
      ),
      DramaEpisode(
        id: 'episode-002',
        dramaId: 'drama-city-reborn',
        title: '重生后我在都市开挂',
        seasonLabel: '第1季',
        tags: ['真人剧', '逆袭', '都市', '爽文'],
        episodeCount: 128,
        videoAssetPath: _cityRebornVideoAssetPath,
        videoResolution: VideoResolution(width: 720, height: 1280),
        progress: 0.42,
        stats: EpisodeStats(
          favoriteCount: 726000,
          commentCount: 863,
          likeCount: 58100,
        ),
        commentPreview: '这一集反转太密了...',
        followerText: '系列剧 · 都市重生 | 共89万人在追',
      ),
      DramaEpisode(
        id: 'episode-003',
        dramaId: 'drama-system-online',
        title: '逆袭系统加载中',
        seasonLabel: '第2季',
        tags: ['漫剧', '系统', '成长', '热血'],
        episodeCount: 204,
        videoAssetPath: _systemOnlineVideoAssetPath,
        videoResolution: VideoResolution(width: 864, height: 480),
        progress: 0.63,
        stats: EpisodeStats(
          favoriteCount: 1154000,
          commentCount: 2097,
          likeCount: 136000,
        ),
        commentPreview: '主角终于醒悟了...',
        followerText: '系列剧 · 系统人生 | 共154万人在追',
      ),
    ];
  }
}
