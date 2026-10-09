import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/generated_scenes.dart';
import '../audio/sound_engine.dart';
import 'app_state.dart';

/// AUDIO — one controller for both the generated soundscape and the streamed
/// library, because the original shares volume, the sleep timer and the sky
/// tint between them (`A.vol`, `A.sm`/`A.sleep`, and the tint in `skyNow`).
class AudioController extends ChangeNotifier {
  AudioController(this.app) {
    _engine = SoundEngine();
  }

  final AppState app;
  final SoundEngine _engine;
  final AudioPlayer _lib = AudioPlayer();

  final Random _rnd = Random();

  // ---- generated ----
  bool on = false;
  String key = '';
  Scene scene = kScenes['dawn']!;
  List<double> mix = kScenes['dawn']!.mix.toList();
  int ci = 0;
  final Map<String, double> _nx = {};

  // ---- library ----
  String cat = 'Ambient';
  Track? curT;
  int errs = 0;
  Duration _libDuration = Duration.zero;
  Duration _libPosition = Duration.zero;
  bool _libPlaying = false;
  bool _seeking = false;

  // ---- shared ----
  double vol = .6;
  int sm = 0; // sleep minutes (0 = off)
  int sleepAtMs = 0;

  Timer? _timer;
  double _clock = 0;

  bool get libOn => curT != null && _libPlaying;
  double get libVolume => min(1, vol * 1.2);
  Duration get libDuration => _libDuration;
  Duration get libPosition => _libPosition;
  bool get libPaused => !_libPlaying;
  bool get seeking => _seeking;
  set seeking(bool v) => _seeking = v;

  /// Sky tint — the generated scene colour, else the library track's category.
  Color? get tint {
    if (on) return scene.color;
    if (libOn && curT != null) return kCategoryColors[curT!.catList.first] ?? kScenes['deep']!.color;
    return null;
  }

  String get dockLabel => on ? scene.name : libOn ? (curT?.title ?? 'Sound') : 'Sound';

  List<Track> get tracks => kLibrary.where((t) => t.catList.contains(cat)).toList();

  void start() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 400), (_) => _tick());
    _lib.playerStateStream.listen((s) {
      _libPlaying = s.playing && s.processingState != ProcessingState.completed;
      notifyListeners();
    });
    _lib.positionStream.listen((p) {
      if (!_seeking) _libPosition = p;
      notifyListeners();
    });
    _lib.durationStream.listen((d) {
      _libDuration = d ?? Duration.zero;
      notifyListeners();
    });
  }

  // -------------------------------------------------------------------------
  // Generated soundscape
  // -------------------------------------------------------------------------
  Future<void> play(String sceneKey) async {
    await libPause();
    scene = kScenes[sceneKey]!;
    key = sceneKey;
    mix = scene.mix.toList();
    on = true;
    ci = 0;
    final t = _clock;
    _nx
      ..['drop'] = t
      ..['life'] = t
      ..['fire'] = t
      ..['bell'] = t + 2
      ..['pad'] = t;
    await _engine.play(sceneKey);
    _engine.setLayerGains(_scaledMix());
    notifyListeners();
  }

  List<double> _scaledMix() => mix;

  Future<void> stop() async {
    if (!on) return;
    on = false;
    sm = 0;
    sleepAtMs = 0;
    await _engine.stop();
    notifyListeners();
  }

  void setMixLayer(int i, double v) {
    mix[i] = v;
    _engine.setLayerGains(_scaledMix());
    notifyListeners();
  }

  void setVolume(double v) {
    vol = v;
    _lib.setVolume(libVolume);
    notifyListeners();
  }

  void setSleep(int minutes) {
    sm = minutes;
    sleepAtMs = minutes > 0 ? DateTime.now().millisecondsSinceEpoch + minutes * 60000 : 0;
    notifyListeners();
  }

  void _tick() {
    _clock = DateTime.now().millisecondsSinceEpoch / 1000;
    if (on) {
      if (sleepAtMs != 0 && DateTime.now().millisecondsSinceEpoch > sleepAtMs) {
        stop();
      } else {
        _scheduleEvents();
        _engine.modulate(_clock);
      }
    }
    if (sleepAtMs != 0 && !on && !_libPlaying && DateTime.now().millisecondsSinceEpoch > sleepAtMs) {
      sm = 0;
      sleepAtMs = 0;
      _fadeLib();
      notifyListeners();
    }
  }

  void _scheduleEvents() {
    final t0 = _clock;
    final til = t0 + 1.5;
    final ng = AppState.isNight(DateTime.now());

    void due(String k, void Function(double t) fn, double Function() gap) {
      var next = _nx[k] ?? t0;
      while (next < til) {
        final t = max(next, t0);
        fn(t);
        next = t + gap();
      }
      _nx[k] = next;
    }

    due('drop', (t) => mix[2] > .02 ? _engine.drop(mix[2]) : null,
        () => -log(1 - _rnd.nextDouble()) * max(.016, .095 - .075 * mix[2]));
    due('life', (t) => mix[5] > .02 ? (ng ? _engine.cricket(mix[5]) : _engine.chirp(mix[5])) : null,
        () => ng ? .12 + _rnd.nextDouble() * (.7 - .4 * mix[5]) : .9 + _rnd.nextDouble() * 5);
    due('fire', (t) => mix[6] > .02 ? _engine.crackle(mix[6]) : null,
        () => .06 + _rnd.nextDouble() * (.5 - .3 * mix[6]));
    due('bell', (t) => mix[1] > .02 ? _engine.bell(scene.root, scene.scale, mix[1], scene.gap) : null,
        () => scene.gap * (.5 + _rnd.nextDouble() * 1.5));
    due('pad', (t) => _engine.chord(scene.root, scene.mode, ci++), () => 14);
  }

  // -------------------------------------------------------------------------
  // Library
  // -------------------------------------------------------------------------
  Future<void> libPause() async {
    if (_libPlaying) await _lib.pause();
  }

  Future<void> setCategory(String c) async {
    cat = c;
    notifyListeners();
  }

  Future<void> playTrack(Track t, {bool fresh = true}) async {
    if (on) await stop();
    curT = t;
    if (fresh) errs = 0;
    try {
      await _lib.setUrl(t.url);
      await _lib.setLoopMode(t.loop ? LoopMode.one : LoopMode.off);
      await _lib.setVolume(libVolume);
      _lib.play();
      notifyListeners();
    } catch (_) {
      _onLibError();
    }
  }

  Future<void> togglePlay() async {
    if (curT == null) {
      final l = tracks;
      if (l.isNotEmpty) await playTrack(l.first);
      return;
    }
    if (_libPlaying) {
      await _lib.pause();
    } else {
      _lib.play();
    }
  }

  Future<void> step(int d, {bool fresh = true}) async {
    final l = tracks;
    if (l.isEmpty) return;
    var i = l.indexOf(curT!);
    i = i < 0 ? 0 : (i + d + l.length) % l.length;
    await playTrack(l[i], fresh: fresh);
  }

  Future<void> seekFraction(double f) async {
    if (_libDuration > Duration.zero) {
      await _lib.seek(_libDuration * f);
    }
  }

  void _onLibError() {
    if (curT == null) return;
    errs++;
    if (errs < tracks.length) {
      step(1, fresh: false);
    } else {
      app.say('No track here could load. Check your connection.');
    }
    notifyListeners();
  }

  Future<void> _fadeLib() async {
    if (!_libPlaying) return;
    final v = libVolume;
    for (int n = 1; n <= 20; n++) {
      await _lib.setVolume(max(0, v * (1 - n / 20)));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    await _lib.pause();
    await _lib.setVolume(v);
  }

  Future<void> silenceAll() async {
    await stop();
    await libPause();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.deinit();
    _lib.dispose();
    super.dispose();
  }
}
