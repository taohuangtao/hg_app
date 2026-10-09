/// 首页顶部的剧集频道。
///
/// 枚举顺序即频道栏展示顺序，下标可直接作为 [PlayerControllerState.channelIndex]。
enum PlayerChannel {
  follow('关注'),
  comic('漫剧'),
  liveAction('真人剧'),
  recommended('推荐');

  const PlayerChannel(this.label);

  final String label;

  static const PlayerChannel defaultChannel = recommended;

  /// [defaultChannel] 的下标。枚举的 `index` 不是常量表达式，
  /// 无法直接用于 `const` 默认值，这里显式声明并由测试保证与枚举顺序一致。
  static const int defaultChannelIndex = 3;

  /// 测试与语义化定位用的稳定标记。
  String get keyName => switch (this) {
    PlayerChannel.follow => 'follow',
    PlayerChannel.comic => 'comic',
    PlayerChannel.liveAction => 'live-action',
    PlayerChannel.recommended => 'recommended',
  };
}
