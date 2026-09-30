import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/drama_episode.dart';

final videoPlaybackEnabledProvider = Provider<bool>((ref) => true);

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerControllerState>(
      PlayerController.new,
    );

@immutable
class PlayerControllerState {
  const PlayerControllerState({
    this.currentIndex = 0,
    this.isPlaying = true,
    this.preloadedIndex = 1,
    this.likedEpisodeIds = const {},
    this.favoriteEpisodeIds = const {},
    this.trackedDramaIds = const {},
  });

  final int currentIndex;
  final bool isPlaying;
  final int? preloadedIndex;
  final Set<String> likedEpisodeIds;
  final Set<String> favoriteEpisodeIds;
  final Set<String> trackedDramaIds;

  bool isLiked(String episodeId) => likedEpisodeIds.contains(episodeId);

  bool isFavorited(String episodeId) => favoriteEpisodeIds.contains(episodeId);

  bool isTracked(String dramaId) => trackedDramaIds.contains(dramaId);

  int favoriteCountFor(DramaEpisode episode) {
    return episode.stats.favoriteCount + (isFavorited(episode.id) ? 1 : 0);
  }

  int likeCountFor(DramaEpisode episode) {
    return episode.stats.likeCount + (isLiked(episode.id) ? 1 : 0);
  }

  PlayerControllerState copyWith({
    int? currentIndex,
    bool? isPlaying,
    int? preloadedIndex,
    Set<String>? likedEpisodeIds,
    Set<String>? favoriteEpisodeIds,
    Set<String>? trackedDramaIds,
  }) {
    return PlayerControllerState(
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      preloadedIndex: preloadedIndex ?? this.preloadedIndex,
      likedEpisodeIds: likedEpisodeIds ?? this.likedEpisodeIds,
      favoriteEpisodeIds: favoriteEpisodeIds ?? this.favoriteEpisodeIds,
      trackedDramaIds: trackedDramaIds ?? this.trackedDramaIds,
    );
  }
}

class PlayerController extends Notifier<PlayerControllerState> {
  @override
  PlayerControllerState build() {
    return const PlayerControllerState();
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(
      currentIndex: index,
      isPlaying: true,
      preloadedIndex: index + 1,
    );
  }

  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void toggleLike(String episodeId) {
    final next = Set<String>.from(state.likedEpisodeIds);
    next.contains(episodeId) ? next.remove(episodeId) : next.add(episodeId);
    state = state.copyWith(likedEpisodeIds: next);
  }

  void toggleFavorite(String episodeId) {
    final next = Set<String>.from(state.favoriteEpisodeIds);
    next.contains(episodeId) ? next.remove(episodeId) : next.add(episodeId);
    state = state.copyWith(favoriteEpisodeIds: next);
  }

  void toggleTrackDrama(String dramaId) {
    final next = Set<String>.from(state.trackedDramaIds);
    next.contains(dramaId) ? next.remove(dramaId) : next.add(dramaId);
    state = state.copyWith(trackedDramaIds: next);
  }
}
