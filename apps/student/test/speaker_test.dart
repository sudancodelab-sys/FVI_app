import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fvi_student/src/audio/speaker.dart';
import 'package:fvi_student/src/content/model.dart';
import 'package:just_audio/just_audio.dart';

/// A player that records what it is asked to play; [finish] ends the clip.
class FakePlayer implements AudioPlayer {
  final _states = StreamController<ProcessingState>.broadcast(sync: true);
  final played = <String>[];
  final playedAt = <Duration>[];
  final clock = Stopwatch()..start();
  String? _loaded;
  int stops = 0;

  void finish() => _states.add(ProcessingState.completed);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #processingStateStream:
        return _states.stream;
      case #setAudioSource:
        _loaded = (invocation.positionalArguments.first as UriAudioSource).uri.path.substring(1); // asset:///…
        return Future<Duration?>.value();
      case #play:
        played.add(_loaded!);
        playedAt.add(clock.elapsed);
        return Future<void>.value();
      case #stop:
        stops++;
        return Future<void>.value();
      case #dispose:
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeBundle extends CachingAssetBundle {
  FakeBundle(this.manifest);

  final Map<String, Object?> manifest;

  @override
  Future<ByteData> load(String key) async => throw FlutterError('no asset $key');

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key != Speaker.manifestPath) throw FlutterError('no asset $key');
    return jsonEncode(manifest);
  }
}

Spoken spoken(String id) => Spoken(text: id, id: id, voice: 'narrator');

/// Waits (in real time) until [done] is true.
Future<void> until(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(done(), isTrue);
}

void main() {
  late FakePlayer player;
  late Speaker speaker;

  setUp(() {
    player = FakePlayer();
    speaker = Speaker(
      player: player,
      bundle: FakeBundle({
        'format': 1,
        'clips': {
          'lv/01/story.0': {'file': 'a.ogg', 'ms': 1000},
          'lv/01/story.1': {'file': 'b.ogg', 'ms': 1000},
          'lv/02/script.0': {'file': 'p0.ogg', 'ms': 3000, 'slot': 3000},
          'lv/02/script.1': {'file': 'p1.ogg', 'ms': 2000},
        },
      }),
    );
  });

  tearDown(() => speaker.dispose());

  test('plays the clip of a text', () async {
    await speaker.play(spoken('lv/01/story.0'));
    expect(player.played, ['assets/audio/a.ogg']);
    expect(speaker.current, 'lv/01/story.0');
  });

  test('plays a lesson in order, with the gap between clips', () async {
    await speaker.playAll([spoken('lv/01/story.0'), spoken('lv/01/story.1')]);
    expect(speaker.playingAll, isTrue);
    player.finish();
    await until(() => player.played.length == 2);
    expect(player.played, ['assets/audio/a.ogg', 'assets/audio/b.ogg']);
    expect(player.playedAt[1] - player.playedAt[0], greaterThanOrEqualTo(Speaker.gap));
    player.finish();
    await until(() => speaker.current == null);
  });

  test('a podcast line runs into the next with no gap', () async {
    await speaker.playAll([spoken('lv/02/script.0'), spoken('lv/02/script.1')]);
    player.finish();
    await until(() => player.played.length == 2);
    expect(player.playedAt[1] - player.playedAt[0], lessThan(Speaker.gap));
  });

  test('a text with no clip is reported and nothing plays', () async {
    Spoken? missing;
    speaker.onMissing = (item) => missing = item;
    await speaker.play(spoken('lv/09/story.0'));
    expect(missing?.id, 'lv/09/story.0');
    expect(player.played, isEmpty);
    expect(speaker.current, isNull);
  });

  test('a new clip stops the one before', () async {
    await speaker.playAll([spoken('lv/01/story.0'), spoken('lv/01/story.1')]);
    await speaker.play(spoken('lv/02/script.1'));
    expect(player.stops, 2);
    expect(speaker.current, 'lv/02/script.1');
    expect(speaker.playingAll, isFalse);
    player.finish();
    await Future<void>.delayed(Speaker.gap * 2);
    expect(player.played.last, 'assets/audio/p1.ogg');
    expect(speaker.current, isNull);
  });
}
