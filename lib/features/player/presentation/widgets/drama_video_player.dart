import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:video_player/video_player.dart';

import '../../application/episode_playback_handle.dart';
import '../../domain/drama_episode.dart';

class DramaVideoPlayer extends StatefulWidget {
  const DramaVideoPlayer({
    super.key,
    required this.assetPath,
    required this.resolution,
    required this.isPlaying,
    required this.enableController,
    required this.onTogglePlay,
    required this.playback,
    this.tapLayerKey,
  });

  final String assetPath;
  final VideoResolution resolution;
  final bool isPlaying;
  final bool enableController;
  final VoidCallback onTogglePlay;

  /// 用于上报真实播放进度、并对外提供 seek 能力的共享句柄。
  final EpisodePlaybackHandle playback;
  final Key? tapLayerKey;

  @override
  State<DramaVideoPlayer> createState() => _DramaVideoPlayerState();
}

class _DramaVideoPlayerState extends State<DramaVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.enableController) {
      _createController();
    }
  }

  @override
  void didUpdateWidget(covariant DramaVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback != widget.playback) {
      oldWidget.playback.detach();
      _rebindPlayback();
    }

    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.enableController != widget.enableController) {
      _disposeController();
      if (widget.enableController) {
        _createController();
      }
      return;
    }

    _syncPlayback();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _createController() {
    _error = null;
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;
    controller
        .initialize()
        .then((_) async {
          await controller.setLooping(true);
          if (!mounted || _controller != controller) {
            return;
          }
          controller.addListener(_handleControllerUpdate);
          widget.playback.attach(controller.seekTo);
          if (widget.isPlaying) {
            await controller.play();
          }
          if (mounted) {
            setState(() {});
          }
          _handleControllerUpdate();
        })
        .catchError((Object error) {
          if (mounted) {
            setState(() {
              _error = error;
            });
          }
        });
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    widget.playback.detach();
    if (controller != null) {
      controller.removeListener(_handleControllerUpdate);
      unawaited(controller.dispose());
    }
  }

  /// 把当前 controller 的播放位置同步给共享句柄。
  void _handleControllerUpdate() {
    final controller = _controller;
    if (controller == null || _error != null) {
      return;
    }

    final value = controller.value;
    if (!value.isInitialized || value.duration <= Duration.zero) {
      return;
    }

    widget.playback.report(position: value.position, duration: value.duration);
  }

  /// 句柄被替换时，重新绑定已就绪的 controller。
  void _rebindPlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    widget.playback.attach(controller.seekTo);
    _handleControllerUpdate();
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (widget.isPlaying && !controller.value.isPlaying) {
      unawaited(controller.play());
    } else if (!widget.isPlaying && controller.value.isPlaying) {
      unawaited(controller.pause());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!widget.enableController || controller == null || !initialized)
          MockDramaArtwork(error: _error != null)
        else
          _VideoSurface(controller: controller, resolution: widget.resolution),
        if (_error != null)
          const _PlayerOverlay(icon: Icons.refresh_rounded, label: '播放失败，轻触重试')
        else if (widget.enableController && !initialized)
          const _LoadingOverlay()
        else if (!widget.enableController || !widget.isPlaying)
          const _PlayerOverlay(icon: Icons.play_arrow_rounded),
        Positioned.fill(
          child: _VideoTapLayer(
            layerKey: widget.tapLayerKey,
            intercepting: kIsWeb && widget.enableController,
            onTap: _error == null ? widget.onTogglePlay : _retry,
          ),
        ),
      ],
    );
  }

  void _retry() {
    _disposeController();
    if (widget.enableController) {
      setState(_createController);
    }
  }
}

class _VideoTapLayer extends StatelessWidget {
  const _VideoTapLayer({
    required this.layerKey,
    required this.intercepting,
    required this.onTap,
  });

  final Key? layerKey;
  final bool intercepting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      intercepting: intercepting,
      child: GestureDetector(
        key: layerKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({required this.controller, required this.resolution});

  final VideoPlayerController controller;
  final VideoResolution resolution;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: resolution.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }
}

class _PlayerOverlay extends StatelessWidget {
  const _PlayerOverlay({required this.icon, this.label});

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xCCFFFFFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF111111), size: 38),
          ),
          if (label != null) ...[
            const SizedBox(height: 8),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MockDramaArtwork extends StatelessWidget {
  const MockDramaArtwork({super.key, this.error = false});

  final bool error;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DramaArtworkPainter(error: error),
      child: const SizedBox.expand(),
    );
  }
}

class _DramaArtworkPainter extends CustomPainter {
  const _DramaArtworkPainter({required this.error});

  final bool error;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 390;
    final scaleY = size.height / 221;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = error ? const Color(0xFF302020) : const Color(0xFFA9A66A);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 221), paint);

    paint.color = const Color(0xFFB8B078);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 62), paint);

    paint.color = const Color(0xFF52624A);
    canvas.drawOval(const Rect.fromLTWH(0, 0, 130, 70), paint);
    paint.color = const Color(0xFF314432);
    canvas.drawOval(const Rect.fromLTWH(117, 0, 125, 70), paint);
    paint.color = const Color(0xFF27321E);
    canvas.drawOval(const Rect.fromLTWH(250, 0, 140, 72), paint);
    paint.color = const Color(0xFFC9B66B);
    canvas.drawOval(const Rect.fromLTWH(205, 0, 76, 78), paint);

    paint.color = const Color(0xBBECE6D7);
    for (final x in [14.0, 64.0, 116.0, 168.0, 222.0, 276.0, 330.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 64, 9, 64),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    paint.color = const Color(0xFF7B8A50);
    canvas.drawRect(const Rect.fromLTWH(0, 126, 390, 32), paint);

    paint.color = const Color(0xFFC96A48);
    final track = Path()
      ..moveTo(0, 105)
      ..quadraticBezierTo(165, 83, 390, 115)
      ..lineTo(390, 221)
      ..lineTo(0, 221)
      ..close();
    canvas.drawPath(track, paint);

    final linePaint = Paint()
      ..color = const Color(0xAAF3D6C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final y in [116.0, 124.0, 132.0, 142.0]) {
      final path = Path()
        ..moveTo(-20, y + 36)
        ..quadraticBezierTo(150, y, 410, y + 5);
      canvas.drawPath(path, linePaint);
    }

    paint.color = const Color(0xFFDDA481);
    canvas.drawOval(const Rect.fromLTWH(149, 67, 82, 88), paint);

    paint.color = const Color(0xFF111111);
    final hair = Path()
      ..moveTo(127, 102)
      ..cubicTo(126, 48, 166, 26, 202, 41)
      ..cubicTo(245, 46, 263, 82, 260, 118)
      ..cubicTo(245, 97, 227, 86, 221, 118)
      ..cubicTo(207, 88, 188, 75, 177, 118)
      ..cubicTo(165, 92, 146, 89, 127, 102)
      ..close();
    canvas.drawPath(hair, paint);

    paint.color = const Color(0xFF14191D);
    final hoodie = Path()
      ..moveTo(84, 221)
      ..cubicTo(100, 158, 140, 139, 195, 139)
      ..cubicTo(249, 139, 288, 164, 304, 221)
      ..close();
    canvas.drawPath(hoodie, paint);

    paint.color = const Color(0xFFC88869);
    canvas.drawOval(const Rect.fromLTWH(170, 128, 36, 34), paint);

    paint.color = const Color(0xFF2B1612);
    canvas.drawOval(const Rect.fromLTWH(164, 102, 18, 6), paint);
    canvas.drawOval(const Rect.fromLTWH(198, 102, 18, 6), paint);

    final mouthPaint = Paint()
      ..color = const Color(0xFF3A1612)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final mouth = Path()
      ..moveTo(181, 131)
      ..quadraticBezierTo(195, 139, 209, 131);
    canvas.drawPath(mouth, mouthPaint);

    paint.color = const Color(0x08FFFFFF);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 221), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DramaArtworkPainter oldDelegate) {
    return oldDelegate.error != error;
  }
}
