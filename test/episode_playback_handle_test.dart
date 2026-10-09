import 'package:flutter_test/flutter_test.dart';
import 'package:hg_app/features/player/application/episode_playback_handle.dart';

void main() {
  test('starts with empty progress and no seek capability', () {
    final handle = EpisodePlaybackHandle();

    expect(handle.ratio, 0);
    expect(handle.hasValue, false);
    expect(handle.canSeek, false);
    expect(handle.duration, Duration.zero);
  });

  test('reports playback progress as a ratio', () {
    final handle = EpisodePlaybackHandle();
    var notified = 0;
    handle.addListener(() => notified++);

    handle.report(
      position: const Duration(seconds: 25),
      duration: const Duration(seconds: 100),
    );

    expect(handle.ratio, closeTo(0.25, 0.0001));
    expect(handle.hasValue, true);
    expect(handle.position, const Duration(seconds: 25));
    expect(handle.duration, const Duration(seconds: 100));
    expect(notified, 1);

    handle.dispose();
  });

  test('ignores invalid duration', () {
    final handle = EpisodePlaybackHandle();

    handle.report(
      position: const Duration(seconds: 3),
      duration: Duration.zero,
    );

    expect(handle.hasValue, false);
    expect(handle.ratio, 0);

    handle.dispose();
  });

  test('clamps reported position into the duration range', () {
    final handle = EpisodePlaybackHandle();

    handle.report(
      position: const Duration(seconds: 200),
      duration: const Duration(seconds: 100),
    );
    expect(handle.ratio, 1);

    handle.report(
      position: const Duration(seconds: -10),
      duration: const Duration(seconds: 100),
    );
    expect(handle.ratio, 0);

    handle.dispose();
  });

  test('seeks by ratio through the attached player', () async {
    final handle = EpisodePlaybackHandle();
    final targets = <Duration>[];

    handle.attach((target) async {
      targets.add(target);
    });
    handle.report(
      position: const Duration(seconds: 10),
      duration: const Duration(seconds: 40),
    );

    await handle.seekToRatio(0.5);

    expect(handle.canSeek, true);
    expect(targets, <Duration>[const Duration(seconds: 20)]);

    handle.dispose();
  });

  test('does not seek without a player or duration', () async {
    final handle = EpisodePlaybackHandle();
    var calls = 0;

    await handle.seekToRatio(0.5);
    expect(calls, 0);

    handle.attach((_) async => calls++);
    await handle.seekToRatio(0.5);
    expect(calls, 0, reason: '没有时长时不应发起跳转');

    handle.dispose();
  });

  test('detach clears progress and disables seeking', () async {
    final handle = EpisodePlaybackHandle();
    var calls = 0;

    handle.attach((_) async => calls++);
    handle.report(
      position: const Duration(seconds: 10),
      duration: const Duration(seconds: 20),
    );
    expect(handle.ratio, closeTo(0.5, 0.0001));

    handle.detach();

    expect(handle.ratio, 0);
    expect(handle.hasValue, false);
    expect(handle.canSeek, false);

    await handle.seekToRatio(0.8);
    expect(calls, 0);

    handle.dispose();
  });
}
