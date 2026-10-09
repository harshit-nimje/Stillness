import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/tokens.dart';

/// ---------------------------------------------------------------------------
/// SKY
/// The whole interface takes its colour from the real clock. A static layer
/// (gradient + hills) is cached and repainted only when the colours have moved
/// enough; the moving layer (sun/moon, stars, rain, mist, waves, scene art,
/// the breathing circle) is drawn at ~30fps.
///
/// This is a direct port of the original Canvas renderer. It is a
/// [ChangeNotifier] used as the `repaint` listenable of a [CustomPainter], so
/// ticking it repaints the canvas WITHOUT rebuilding the widget tree.
/// ---------------------------------------------------------------------------

Color hx(String s) {
  final v = int.parse(s.substring(1), radix: 16);
  return Color(0xFF000000 | v);
}

class SkyKeyframe {
  final double h;
  final Color top, bot, ac;
  const SkyKeyframe(this.h, this.top, this.bot, this.ac);
}

/// `K` — the clock keyframes, in hours.
final List<SkyKeyframe> skyKeyframes = [
  SkyKeyframe(0, hx('#b9b3e8'), hx('#dcd2f2'), hx('#6a5acd')),
  SkyKeyframe(5, hx('#c3b0e0'), hx('#f0cfe0'), hx('#9a5fb8')),
  SkyKeyframe(6.5, hx('#f6c9a8'), hx('#fbe6cf'), hx('#d9784a')),
  SkyKeyframe(9, hx('#bcd9f0'), hx('#eaf4f7'), hx('#3f86c6')),
  SkyKeyframe(13, hx('#a9cff0'), hx('#e3f0f7'), hx('#2f7fc0')),
  SkyKeyframe(17, hx('#c9d3ee'), hx('#f9e3c0'), hx('#b97a2e')),
  SkyKeyframe(19, hx('#e9b6c4'), hx('#f8d2b4'), hx('#c6577a')),
  SkyKeyframe(20.5, hx('#b5a8e0'), hx('#e0c4de'), hx('#7a62c4')),
  SkyKeyframe(24, hx('#b9b3e8'), hx('#dcd2f2'), hx('#6a5acd')),
];

/// `skyNow()` — returns [top, bot, ac] for the given hour.
List<Color> skyNow(double hour, {required bool isDark, Color? tint}) {
  int i = 0;
  while (hour >= skyKeyframes[i + 1].h) {
    i++;
  }
  final k0 = skyKeyframes[i], k1 = skyKeyframes[i + 1];
  double f = (hour - k0.h) / (k1.h - k0.h);
  f = f * f * (3 - 2 * f); // smoothstep

  Color jTop = mixColor(k0.top, k1.top, f);
  Color jBot = mixColor(k0.bot, k1.bot, f);
  Color jAc = mixColor(k0.ac, k1.ac, f);

  if (isDark) {
    jTop = mixColor(jTop, const Color(0xFF080A1A), .84);
    jBot = mixColor(jBot, const Color(0xFF080A1A), .84);
    jAc = mixColor(jAc, const Color(0xFFFFFFFF), .45);
  }
  if (tint != null) {
    final tf = isDark ? .2 : .4;
    jTop = mixColor(jTop, tint, tf);
    jBot = mixColor(jBot, tint, tf);
    jAc = mixColor(jAc, tint, .7);
  }
  return [jTop, jBot, jAc];
}

/// The set of live inputs the sky needs each frame, gathered from the
/// controllers by the sky widget.
class SkyInputs {
  bool isDark = false;
  Color? tint;
  bool night = false;
  bool soundOn = false;
  List<double> mix = List.filled(7, 0);
  /// the key of the currently playing generated scene, or null.
  String? sceneKey;
  /// 0..1 progress of an open focus session, or null when focus is closed.
  double? focusProgress;
  bool breatheOn = false;
  String breatheKind = 'box';
  /// seconds since the breathing session began (performance.now()/1000 analog)
  double breatheTime = 0;
  bool reduceMotion = false;
}

class SkyDrop {
  double x, y, l, v, a;
  SkyDrop(this.x, this.y, this.l, this.v, this.a);
}

class SkyVp {
  double x, y, r, s, k;
  SkyVp(this.x, this.y, this.r, this.s, this.k);
}

class SkyMo {
  double x, y, r, v, a;
  SkyMo(this.x, this.y, this.r, this.v, this.a);
}

class SkyStar {
  double x, y, r, s;
  SkyStar(this.x, this.y, this.r, this.s);
}

class SkyController extends ChangeNotifier {
  SkyController() {
    _seed();
  }

  static final Random _r = Random();

  final SkyInputs inputs = SkyInputs();

  /// The app-wide palette. Updated only when the sky colours have actually
  /// moved (throttled exactly like the original `paintBg` trigger), so the
  /// widget tree is not rebuilt every frame.
  final ValueNotifier<Palette> palette =
      ValueNotifier(Palette.forTheme(top: hx('#bcd0ee'), bot: hx('#e6eef7'), ac: hx('#4a63b8'), isDark: false));

  // --- cached static layer ---
  ui.Image? _bg;

  // --- visual state ---
  List<Color> _cur = const [];
  List<Color> _tgt = const [];
  double _ph = 0;
  double _flash = 0;
  double _sx = -1, _sy = 0;
  final List<double> E = List.filled(7, 0);
  final Map<String, double> AR = {};
  double _acc = 0;
  int _lastSkyMs = 0;
  int _lastPaletteMs = 0;
  int _tDrawMs = 0;
  double _tm = 0;

  /// last frame delta in seconds — used by particles in the painter.
  double lastDt = 0;

  double get E2 => E[2];
  double get E3 => E[3];
  double get E4 => E[4];
  double get E5 => E[5];
  double get E6 => E[6];

  // --- particle pools ---
  final List<SkyDrop> _dr = List.generate(150, (_) => SkyDrop(_r.nextDouble(), _r.nextDouble(), 11 + _r.nextDouble() * 26, 260 + _r.nextDouble() * 420, .1 + _r.nextDouble() * .24));
  final List<SkyVp> _vp = List.generate(40, (_) => SkyVp(_r.nextDouble(), _r.nextDouble(), .5 + _r.nextDouble(), _r.nextDouble() * 6.28, .4 + _r.nextDouble()));
  final List<SkyMo> _mo = List.generate(26, (_) => SkyMo(_r.nextDouble(), _r.nextDouble(), 1 + _r.nextDouble() * 2, -.004 - _r.nextDouble() * .01, .05 + _r.nextDouble() * .12));
  final List<SkyStar> _st = List.generate(60, (_) => SkyStar(_r.nextDouble(), _r.nextDouble() * .5, .4 + _r.nextDouble() * 1.1, _r.nextDouble() * 6.28));

  // scene trees (woods)
  final List<SkyTree> _tr = List.generate(14, (i) => SkyTree((i + .5) / 14 + (_r.nextDouble() - .5) * .04, .14 + _r.nextDouble() * .14, .035 + _r.nextDouble() * .03));

  void _seed() {
    _cur = const [];
  }

  /// Called by the sky widget after layout so we know the paint surface.
  Size size = const Size(1, 1);
  double dpr = 1;

  void markDirty() {
    _bg = null;
    _lastSkyMs = 0;
  }

  /// A short bloom of the sun/moon halo (task complete, phase end).
  void flashNow() => _flash = 1.2;

  /// Advance the simulation. [nowMs] is a monotonic millisecond clock (the
  /// Ticker's elapsed time). Mirrors the original `frame(now)`.
  void tick(int nowMs) {
    if (nowMs - _tDrawMs < 32) return; // ~30fps cap
    double dt = (nowMs - _tDrawMs) / 1000.0;
    if (_tDrawMs == 0) dt = 0;
    dt = dt.clamp(0, .08);
    _tDrawMs = nowMs;
    lastDt = dt;
    _ph += dt;

    final now = DateTime.now();
    final hour = now.hour + now.minute / 60.0;

    if (_cur.isEmpty || nowMs - _lastSkyMs > 1000) {
      _tgt = skyNow(hour, isDark: inputs.isDark, tint: inputs.tint);
      _lastSkyMs = nowMs;
      if (_cur.isEmpty) _cur = _tgt.map((c) => c).toList();
    }

    final k = 1 - exp(-dt / 1.5);
    final cur = _cur.toList();
    for (int j = 0; j < cur.length; j++) {
      cur[j] = mixColor(cur[j], _tgt[j], k);
    }
    _cur = cur;

    // scene-art levels + layer levels
    final ke = 1 - exp(-dt / 1.2);
    for (int i = 0; i < 7; i++) {
      final target = inputs.soundOn ? inputs.mix[i] : 0.0;
      E[i] += (target - E[i]) * ke;
    }

    // sun / moon position
    final night = inputs.night;
    final p = inputs.focusProgress ??
        (night ? (hour >= 20 ? hour - 20 : hour + 4) / 9.5 : ((hour - 5.5) / 14.5).clamp(0, 1).toDouble());
    final tx = size.width * (.12 + .76 * p);
    final ty = size.height * (.46 - .28 * sin(pi * p));
    if (_sx < 0) {
      _sx = tx;
      _sy = ty;
    }
    _sx += (tx - _sx) * (1 - exp(-dt / .9));
    _sy += (ty - _sy) * (1 - exp(-dt / .9));
    _flash *= exp(-dt * 1.3);

    // scene-art levels
    const sceneKeys = ['dawn', 'sea', 'woods', 'deep', 'hearth', 'rain'];
    final ka = 1 - exp(-dt / 1.4);
    for (final key in sceneKeys) {
      final target = (inputs.soundOn && inputs.sceneKey == key) ? 1.0 : 0.0;
      final prev = AR[key] ?? 0;
      AR[key] = prev + (target - prev) * ka;
    }

    // scene art levels
    _tm = inputs.reduceMotion ? 0 : _ph;

    if (nowMs - _lastPaletteMs > 500 || _bg == null) {
      _syncPalette();
      _lastPaletteMs = nowMs;
    }

    notifyListeners();
  }

  /// Push the current sky colours into the app palette. Called on a 500ms
  /// throttle (and on resize / theme change), matching the original
  /// `paintBg` cadence — NOT every frame.
  void _syncPalette() {
    if (_cur.length < 3) return;
    palette.value = Palette.forTheme(
      top: _cur[0],
      bot: _cur[1],
      ac: _cur[2],
      isDark: inputs.isDark,
    );
  }

  // --- getters used by the painter ---
  List<Color> get cur => _cur;
  List<Color> get curSafe => _cur.length >= 3 ? _cur : [_tgt.isNotEmpty ? _tgt[0] : const Color(0xFFBCD0EE), const Color(0xFFE6EEF7), const Color(0xFF4A63B8)];
  double get phase => _ph;
  double get flash => _flash;
  double get sunX => _sx;
  double get sunY => _sy;
  double get tm => _tm;
  List<SkyDrop> get drops => _dr;
  List<SkyVp> get vps => _vp;
  List<SkyMo> get mists => _mo;
  List<SkyStar> get stars => _st;
  List<SkyTree> get trees => _tr;

  void setSceneLevel(String key, double v) => AR[key] = v;
  double sceneLevel(String key) => AR[key] ?? 0;
  Map<String, double> get sceneLevels => AR;
}

class SkyTree {
  final double x, h, w;
  SkyTree(this.x, this.h, this.w);
}
