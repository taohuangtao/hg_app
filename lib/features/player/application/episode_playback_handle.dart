import 'dart:async';

import 'package:flutter/foundation.dart';

/// 单集播放进度的共享句柄。
///
/// 播放器侧（DramaVideoPlayer）持有 VideoPlayerController 并上报真实进度、
/// 注册 seek 回调；进度条侧（底部「观看完整漫剧」条）监听它渲染进度并请求跳播。
/// 没有实时数据时（视频未初始化、加载失败、测试环境禁用播放）进度恒为 0。
class EpisodePlaybackHandle extends ChangeNotifier {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _ratio = 0;
  bool _hasValue = false;
  Future<void> Function(Duration target)? _seek;

  /// 当前播放进度，取值 0..1，无数据时为 0。
  double get ratio => _ratio;

  /// 是否收到过有效的播放时长。
  bool get hasValue => _hasValue;

  /// 播放器是否已注册 seek 能力。
  bool get canSeek => _seek != null;

  Duration get position => _position;

  Duration get duration => _duration;

  /// 播放器初始化完成后调用，注册 seek 通道。
  void attach(Future<void> Function(Duration target) seek) {
    _seek = seek;
  }

  /// 播放器销毁或重建前调用，断开 seek 通道并清空进度。
  void detach() {
    _seek = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _hasValue = false;
    _setRatio(0);
  }

  /// 播放器上报最新播放位置，仅在进度变化时通知监听者。
  void report({required Duration position, required Duration duration}) {
    if (duration <= Duration.zero) {
      return;
    }

    final clampedPosition = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    final nextRatio = (clampedPosition.inMicroseconds / duration.inMicroseconds)
        .clamp(0.0, 1.0);

    final changed =
        clampedPosition != _position ||
        duration != _duration ||
        nextRatio != _ratio;

    _position = clampedPosition;
    _duration = duration;
    _hasValue = true;

    if (changed) {
      _ratio = nextRatio;
      notifyListeners();
    } else {
      _ratio = nextRatio;
    }
  }

  /// 按比例跳转，无播放器或未拿到时长时静默忽略。
  Future<void> seekToRatio(double target) {
    final seek = _seek;
    if (seek == null || _duration <= Duration.zero) {
      return Future<void>.value();
    }

    final clamped = target.clamp(0.0, 1.0);
    final microseconds = (_duration.inMicroseconds * clamped).round();
    return seek(Duration(microseconds: microseconds));
  }

  void _setRatio(double value) {
    if (_ratio == value) {
      return;
    }
    _ratio = value;
    notifyListeners();
  }
}
