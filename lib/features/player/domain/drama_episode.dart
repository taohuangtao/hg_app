import 'package:flutter/foundation.dart';

@immutable
class DramaEpisode {
  const DramaEpisode({
    required this.id,
    required this.dramaId,
    required this.title,
    required this.seasonLabel,
    required this.tags,
    required this.episodeCount,
    required this.videoAssetPath,
    required this.videoResolution,
    required this.progress,
    required this.stats,
    required this.commentPreview,
    required this.followerText,
  });

  final String id;
  final String dramaId;
  final String title;
  final String seasonLabel;
  final List<String> tags;
  final int episodeCount;
  final String videoAssetPath;
  final VideoResolution videoResolution;
  final double progress;
  final EpisodeStats stats;
  final String commentPreview;
  final String followerText;
}

@immutable
class VideoResolution {
  const VideoResolution({required this.width, required this.height})
    : assert(width > 0),
      assert(height > 0);

  final int width;
  final int height;

  double get aspectRatio => width / height;

  bool get isPortrait => height > width;

  bool get isLandscape => !isPortrait;
}

@immutable
class EpisodeStats {
  const EpisodeStats({
    required this.favoriteCount,
    required this.commentCount,
    required this.likeCount,
  });

  final int favoriteCount;
  final int commentCount;
  final int likeCount;
}
