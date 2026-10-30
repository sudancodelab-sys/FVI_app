import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import '../content/model.dart';

/// The one audio player of the app.
///
/// Every clip goes through it, so two clips can never be heard at once:
/// starting a clip stops the one before, and leaving a lesson stops it all.
/// A clip is found by the id of its text in the audio manifest that the
/// voice generator writes next to the clips.
class Speaker extends ChangeNotifier {
  Speaker({AssetBundle? bundle, AudioPlayer? player})
      : _bundle = bundle ?? rootBundle,
        _player = player ?? AudioPlayer() {
    _subscription = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _advance(_generation);
    });
  }

  static const manifestPath = 'assets/audio/manifest.json';

  /// The pause between two clips when a whole lesson is played. A podcast
  /// line has none: its clip already runs to the next line's printed time.
  static const gap = Duration(milliseconds: 450);

  final AssetBundle _bundle;
  final AudioPlayer _player;
  late final StreamSubscription<ProcessingState> _subscription;
  Map<String, _Clip>? _clips;

  List<Spoken> _queue = const [];
  int _index = -1;

  /// Bumped by every play and stop, so a clip that finishes loading after
  /// the student has moved on is never started.
  int _generation = 0;

  /// Called when a text has no clip yet.
  void Function(Spoken item)? onMissing;

  /// The id of the clip being played, or null.
  String? get current => _index >= 0 && _index < _queue.length ? _queue[_index].id : null;

  /// Whether a list of clips (a whole lesson) is being played.
  bool get playingAll => current != null && _queue.length > 1;

  Future<void> play(Spoken item) => playAll([item]);

  Future<void> playAll(List<Spoken> items, {int from = 0}) async {
    final generation = ++_generation;
    await _player.stop();
    if (generation != _generation) return;
    _queue = List.unmodifiable(items);
    _index = from;
    notifyListeners();
    await _start(generation);
  }

  Future<void> stop() async {
    _generation++;
    _clear();
    await _player.stop();
  }

  Future<void> _start(int generation) async {
    if (generation != _generation) return;
    if (_index >= _queue.length) return _clear();
    final item = _queue[_index];
    final clip = (await _manifest())[item.id];
    if (generation != _generation) return;
    if (clip == null) {
      _clear();
      onMissing?.call(item);
      return;
    }
    try {
      await _player.setAudioSource(AudioSource.asset(clip.asset));
      if (generation != _generation) return;
      unawaited(_player.play());
    } on PlayerInterruptedException {
      // A newer play or stop took over; it owns the player now.
    } on PlayerException {
      if (generation != _generation) return;
      _clear();
      onMissing?.call(item);
    }
  }

  Future<void> _advance(int generation) async {
    if (generation != _generation || _queue.isEmpty) return;
    if (_index + 1 >= _queue.length) return _clear();
    if (!(_clips?[_queue[_index].id]?.timed ?? false)) {
      await Future<void>.delayed(gap);
      if (generation != _generation) return;
    }
    _index++;
    notifyListeners();
    await _start(generation);
  }

  void _clear() {
    _queue = const [];
    _index = -1;
    notifyListeners();
  }

  Future<Map<String, _Clip>> _manifest() async {
    if (_clips != null) return _clips!;
    try {
      final json = jsonDecode(await _bundle.loadString(manifestPath)) as Map<String, dynamic>;
      return _clips = {
        for (final e in (json['clips'] as Map<String, dynamic>).entries)
          e.key: _Clip.fromJson(e.value as Map<String, dynamic>),
      };
    } on FlutterError {
      return _clips = const {};
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// One clip of the manifest.
class _Clip {
  _Clip.fromJson(Map<String, dynamic> json) : asset = 'assets/audio/${json['file']}', timed = json['slot'] != null;

  final String asset;

  /// A podcast line, padded with silence up to the next line's time.
  final bool timed;
}

/// Gives every screen the one [Speaker].
class SpeakerScope extends InheritedNotifier<Speaker> {
  const SpeakerScope({super.key, required Speaker speaker, required super.child}) : super(notifier: speaker);

  /// The speaker, rebuilding [context] whenever the clip changes.
  static Speaker of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SpeakerScope>()!.notifier!;

  /// The speaker, without rebuilding [context].
  static Speaker read(BuildContext context) => context.getInheritedWidgetOfExactType<SpeakerScope>()!.notifier!;
}
