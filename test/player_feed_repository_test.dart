import 'package:flutter_test/flutter_test.dart';
import 'package:hg_app/features/player/data/player_feed_repository.dart';

void main() {
  test('mock feed uses local video assets and complete episode data', () {
    const repository = MockPlayerFeedRepository();

    final episodes = repository.fetchRecommendedEpisodes();

    expect(episodes, isNotEmpty);
    expect(
      episodes.map((episode) => episode.videoAssetPath),
      containsAll([
        '_video/1111.mp4',
        '_video/20260630-145038.mp4',
        '_video/MiniMax_H3_00001_.mp4',
      ]),
    );
    expect(
      episodes.map((episode) => episode.videoAssetPath).toSet(),
      hasLength(3),
    );

    final byPath = {
      for (final episode in episodes) episode.videoAssetPath: episode,
    };
    expect(byPath['_video/1111.mp4']!.videoResolution.width, 640);
    expect(byPath['_video/1111.mp4']!.videoResolution.height, 360);
    expect(byPath['_video/1111.mp4']!.videoResolution.isLandscape, isTrue);
    expect(byPath['_video/20260630-145038.mp4']!.videoResolution.width, 720);
    expect(byPath['_video/20260630-145038.mp4']!.videoResolution.height, 1280);
    expect(
      byPath['_video/20260630-145038.mp4']!.videoResolution.isPortrait,
      isTrue,
    );
    expect(byPath['_video/MiniMax_H3_00001_.mp4']!.videoResolution.width, 864);
    expect(byPath['_video/MiniMax_H3_00001_.mp4']!.videoResolution.height, 480);
    expect(
      byPath['_video/MiniMax_H3_00001_.mp4']!.videoResolution.isLandscape,
      isTrue,
    );

    for (final episode in episodes) {
      expect(episode.id, isNotEmpty);
      expect(episode.dramaId, isNotEmpty);
      expect(episode.title, isNotEmpty);
      expect(episode.tags, isNotEmpty);
      expect(episode.episodeCount, greaterThan(0));
      expect(episode.videoResolution.width, greaterThan(0));
      expect(episode.videoResolution.height, greaterThan(0));
      expect(episode.videoAssetPath, startsWith('_video/'));
      expect(episode.videoAssetPath, isNot(contains('http')));
      expect(episode.videoAssetPath, isNot(contains('token')));
    }
  });
}
