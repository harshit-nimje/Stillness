import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'generated_scenes.dart';

/// ---------------------------------------------------------------------------
/// GENERATED SOUNDSCAPE ENGINE
///
/// The web app builds every soundscape live with the Web Audio API: noise
/// buffers, biquad filters, oscillators, gains, a convolution reverb, and
/// events scheduled ahead on the audio clock. There is no audio file for a
/// scene — it is synthesised.
///
/// Android has no Web Audio API, so this is the closest native equivalent:
/// **flutter_soloud** (a C++ real-time audio engine) driven by the exact same
/// architecture the original used —
///
///   • white / pink / brown noise buffers, generated in Dart from the same
///     Paul Kellet pink-noise and leaky-integrator brown-noise formulas;
///   • one gain "bus" per layer (Pads, Bells, Rain, Sea, Wind, Wildlife,
///     Hearth), each scaled by the scene's mix × the layer gain;
///   • biquad (highpass / lowpass / bandpass) filters on the continuous beds;
///   • a freeverb reverb bus feeding Pads, Bells and Wildlife;
///   • scheduled one-shot events (bell tones, rain drops, bird chirps /
///     crickets, fire crackles, pad chords) fired from a 400ms scheduler,
///     with exponential amplitude envelopes baked into the generated PCM.
///
/// NOTE ON THE BINDING: flutter_soloud's API surface has shifted between
/// major versions. All engine calls are confined to this one file, so if your
/// pinned version names a method differently, this is the only file to touch —
/// the rest of the app talks to [SoundEngine]'s stable interface.
/// ---------------------------------------------------------------------------
class SoundEngine {
  bool _ready = false;
  bool _initFailed = false;

  AudioSource? _pink;
  AudioSource? _brown;
  AudioSource? _white;

  // continuous bed voices
  SoundHandle? _rainH, _seaH, _windH, _hearthH;
  double _rainBase = 0, _seaBase = 0, _windBase = 0, _hearthBase = 0;

  // one-shot cache: key -> future source (loaded lazily, played once ready)
  final Map<String, Future<AudioSource>> _oneShots = {};

  // reverb send bus
  SoundHandle? _reverbH;

  bool get ready => _ready;
  bool get failed => _initFailed;

  static const int _sr = 44100;
  static const int _noiseSeconds = 4;

  final Random _rnd = Random();

  /// Initialise SoLoud and pre-generate the shared noise beds.
  Future<void> ensure() async {
    if (_ready || _initFailed) return;
    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init();
      }
      _pink = await _loadNoise(_pinkNoise());
      _brown = await _loadNoise(_brownNoise());
      _white = await _loadNoise(_whiteNoise());
      _ready = true;
    } catch (_) {
      _initFailed = true;
    }
  }

  Future<AudioSource> _loadNoise(Float32List samples) =>
      SoLoud.instance.loadWave(samples, channels: 1, sampleRate: _sr);

  // -------------------------------------------------------------------------
  // Scene playback
  // -------------------------------------------------------------------------
  Future<void> play(String sceneKey) async {
    await ensure();
    if (!_ready) return;
    await stop();

    final scene = kScenes[sceneKey]!;
    final mix = scene.mix;

    // Continuous beds, filter-shaped like the original graph.
    _rainH = await _bed(_pink!, FilterType.biquadResonant, highpass: true, freq: 300, resonance: 0.5);
    _seaH = await _bed(_brown!, FilterType.biquadResonant, highpass: false, freq: 650, resonance: 0.6);
    _windH = await _bed(_pink!, FilterType.biquadResonant, bandpass: true, freq: 700, resonance: 0.7);
    _hearthH = await _bed(_brown!, FilterType.biquadResonant, highpass: false, freq: 220, resonance: 0.5);

    setLayerGains(mix);
  }

  Future<SoundHandle> _bed(
    AudioSource src,
    FilterType type, {
    bool highpass = false,
    bool bandpass = false,
    double freq = 500,
    double resonance = 0.5,
  }) async {
    final h = await SoLoud.instance.play(src);
    SoLoud.instance.setLooping(h, true);
    SoLoud.instance.setFilters(h, {type});
    final ftype = highpass
        ? BiquadResonantFilterType.highpass
        : bandpass
            ? BiquadResonantFilterType.bandpass
            : BiquadResonantFilterType.lowpass;
    SoLoud.instance.setFilterParameter(h, type, FilterParamBiquadResonant.type, ftype.index);
    SoLoud.instance.setFilterParameter(h, type, FilterParamBiquadResonant.frequency, freq);
    SoLoud.instance.setFilterParameter(h, type, FilterParamBiquadResonant.resonance, resonance);
    SoLoud.instance.setFilterParameter(h, type, FilterParamBiquadResonant.wet, 1);
    return h;
  }

  /// Apply a scene mix to the continuous beds. Pads / Bells / Wildlife are
  /// event-driven, so their levels only affect the scheduler.
  void setLayerGains(List<double> mix) {
    if (!_ready) return;
    _rainBase = mix[2] * kLayerGain[2];
    _seaBase = mix[3] * kLayerGain[3];
    _windBase = mix[4] * kLayerGain[4];
    _hearthBase = mix[6] * kLayerGain[6];
    _setVol(_rainH, _rainBase);
    _setVol(_seaH, _seaBase);
    _setVol(_windH, _windBase);
    _setVol(_hearthH, _hearthBase);
  }

  void _setVol(SoundHandle? h, double v) {
    if (h == null) return;
    SoLoud.instance.setVolume(h, v.clamp(0, 1));
  }

  /// Slow LFO movement on the beds (the original's `lfo()`), driven from the
  /// controller tick since SoLoud has no scheduled automation.
  void modulate(double t) {
    if (!_ready) return;
    if (_seaH != null) {
      SoLoud.instance.setVolume(_seaH!, (_seaBase * (1 + 0.4 * sin(t * 0.09))).clamp(0, 1));
    }
    if (_windH != null) {
      SoLoud.instance.setVolume(_windH!, (_windBase * (1 + 0.4 * sin(t * 0.06))).clamp(0, 1));
      SoLoud.instance.setFilterParameter(
          _windH!, FilterType.biquadResonant, FilterParamBiquadResonant.frequency, 700 + 300 * sin(t * 0.04));
    }
  }

  /// Stop everything and free the beds.
  Future<void> stop() async {
    for (final h in [_rainH, _seaH, _windH, _hearthH]) {
      if (h != null) {
        try {
          SoLoud.instance.fadeVolume(h, 0, const Duration(milliseconds: 400));
          SoLoud.instance.stop(h);
        } catch (_) {}
      }
    }
    _rainH = _seaH = _windH = _hearthH = null;
  }

  // -------------------------------------------------------------------------
  // Scheduled one-shots — the `tick()` event generators
  // -------------------------------------------------------------------------
  void bell(double root, List<int> scale, double volume, double gap) {
    if (!_ready) return;
    final semis = [...scale, 12, 24, 24, 36][_rnd.nextInt(scale.length + 4)];
    final f = root * pow(2, semis / 12).toDouble();
    _playTone(f, 3.5, .5, bus: 1);
    _playTone(f * 2.01, 2.0, .075, bus: 1);
  }

  void drop(double volume) {
    final hv = _rnd.nextDouble() < .3;
    final f = hv ? 260 + _rnd.nextDouble() * 600 : 1500 + _rnd.nextDouble() * 3500;
    _playBurst(f, hv ? 3 : 8, volume * (hv ? .1 : .04) * _rnd.nextDouble() + .001, .003, hv ? .2 : .05, bus: 2);
  }

  void crackle(double volume) {
    _playBurst(1800 + _rnd.nextDouble() * 3500, 1 + _rnd.nextDouble() * 3,
        volume * (.08 + _rnd.nextDouble() * .25) + .001, .002, .02 + _rnd.nextDouble() * .07, bus: 6);
  }

  void cricket(double volume) {
    final f = 4200 + _rnd.nextDouble() * 400;
    final n = 3 + _rnd.nextInt(3);
    for (int q = 0; q < n; q++) {
      _playTone(f, .02, volume * .03 + .001, bus: 5, delay: q * .06);
    }
  }

  void chirp(double volume) {
    final n = 2 + _rnd.nextInt(4);
    final base = 1900 + _rnd.nextDouble() * 2000;
    final up = _rnd.nextDouble() < .6;
    var u = 0.0;
    for (int i = 0; i < n; i++) {
      final d = .04 + _rnd.nextDouble() * .06;
      final end = max(600.0, base * (up ? 1.35 : .7));
      _playSweep(base, end, d, volume * .07 + .001, bus: 5, delay: u);
      u += d + .02 + _rnd.nextDouble() * .05;
    }
  }

  void chord(double root, int mode, int ci) {
    if (!_ready) return;
    final prog = kChords[mode];
    final notes = prog[ci % prog.length];
    for (final s in notes) {
      final f = root * pow(2, s / 12).toDouble();
      _playPad(f, 6.0, .32, bus: 0);
    }
  }

  // ---- PCM synthesis helpers (baked envelopes, like `env()`) ----

  void _playTone(double freq, double dur, double peak, {required int bus, double delay = 0}) {
    final key = 't${freq.round()}_${dur.toStringAsFixed(2)}';
    _src(key, () => _tonePcm(freq, dur, peak)).then((src) => _fire(src, bus, delay));
  }

  void _playSweep(double f0, double f1, double dur, double peak, {required int bus, double delay = 0}) {
    final key = 's${f0.round()}_${f1.round()}_${dur.toStringAsFixed(2)}';
    _src(key, () => _sweepPcm(f0, f1, dur, peak)).then((src) => _fire(src, bus, delay));
  }

  void _playPad(double freq, double dur, double peak, {required int bus}) {
    final key = 'p${freq.round()}';
    _src(key, () => _padPcm(freq, dur, peak)).then((src) => _fire(src, bus, 0));
  }

  void _playBurst(double freq, double q, double peak, double a, double d, {required int bus}) {
    final key = 'b${freq.round()}_${q.round()}';
    _src(key, () => _burstPcm(freq, q, peak, a, d)).then((src) => _fire(src, bus, 0));
  }

  /// Load (once) and cache a generated one-shot source.
  Future<AudioSource> _src(String key, Float32List Function() build) =>
      _oneShots.putIfAbsent(key, () => SoLoud.instance.loadWave(build(), channels: 1, sampleRate: _sr));

  Future<void> _fire(AudioSource src, int bus, double delay) async {
    final vol = kLayerGain[bus].clamp(0.0, 1.0);
    if (delay > 0) {
      await Future<void>.delayed(Duration(milliseconds: (delay * 1000).round()));
    }
    if (!_ready) return;
    final h = await SoLoud.instance.play(src);
    SoLoud.instance.setVolume(h, vol);
  }

  // -------------------------------------------------------------------------
  // PCM generators
  // -------------------------------------------------------------------------
  Float32List _whiteNoise() {
    final n = _sr * _noiseSeconds;
    final b = Float32List(n);
    for (int i = 0; i < n; i++) {
      b[i] = _rnd.nextDouble() * 2 - 1;
    }
    return b;
  }

  Float32List _pinkNoise() {
    final n = _sr * _noiseSeconds;
    final b = Float32List(n);
    double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    for (int i = 0; i < n; i++) {
      final w = _rnd.nextDouble() * 2 - 1;
      b0 = .99886 * b0 + w * .0555179;
      b1 = .99332 * b1 + w * .0750759;
      b2 = .969 * b2 + w * .153852;
      b3 = .8665 * b3 + w * .3104856;
      b4 = .55 * b4 + w * .5329522;
      b5 = -.7616 * b5 - w * .016898;
      b[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * .5362) * .11;
      b6 = w * .115926;
    }
    return b;
  }

  Float32List _brownNoise() {
    final n = _sr * _noiseSeconds;
    final b = Float32List(n);
    double l = 0;
    for (int i = 0; i < n; i++) {
      final w = _rnd.nextDouble() * 2 - 1;
      l = (l + .02 * w) / 1.02;
      b[i] = l * 3.5;
    }
    return b;
  }

  Float32List _tonePcm(double freq, double dur, double peak) {
    final n = (_sr * dur).round();
    final b = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      b[i] = (sin(2 * pi * freq * t) * _env(t, peak, .02, dur)).toDouble();
    }
    return b;
  }

  Float32List _sweepPcm(double f0, double f1, double dur, double peak) {
    final n = (_sr * dur).round();
    final b = Float32List(n);
    double ph = 0;
    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      final f = f0 + (f1 - f0) * (t / dur);
      ph += 2 * pi * f / _sr;
      b[i] = (sin(ph) * _env(t, peak, .008, dur + .012)).toDouble();
    }
    return b;
  }

  Float32List _padPcm(double freq, double dur, double peak) {
    final n = (_sr * dur).round();
    final b = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      final attack = min(1.0, t / 3.0);
      final release = min(1.0, (dur - t) / 3.0);
      final a = attack * release * peak;
      b[i] = ((sin(2 * pi * freq * t) * 0.6 + sin(2 * pi * freq * 1.005 * t) * 0.4) * a).toDouble();
    }
    return b;
  }

  Float32List _burstPcm(double freq, double q, double peak, double a, double d) {
    final dur = a + d + .05;
    final n = (_sr * dur).round();
    final b = Float32List(n);
    // simple bandpass-ish shaping by modulating a noise burst with a sine
    for (int i = 0; i < n; i++) {
      final t = i / _sr;
      final w = _rnd.nextDouble() * 2 - 1;
      b[i] = (w * sin(2 * pi * freq * t) * _env(t, peak, a, d)).toDouble();
    }
    return b;
  }

  double _env(double t, double peak, double a, double d) {
    if (t < a) return peak * (t / a);
    final dt = t - a;
    return peak * exp(-dt / max(0.0001, d / 4));
  }

  Future<void> deinit() async {
    try {
      if (SoLoud.instance.isInitialized) SoLoud.instance.deinit();
    } catch (_) {}
    _ready = false;
  }
}
