import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/tokens.dart';
import 'sky.dart';

/// Direct port of the original Canvas renderer: the cached static layer
/// (gradient + five hills), then the moving layer (stars, sun/moon, waves,
/// rain, mist, embers/fireflies, scene art) and finally the breathing circle.
///
/// Everything is drawn in logical pixels, which is 1:1 with the CSS pixels the
/// original measured, so all the constants (frequencies, radii, alphas) carry
/// over unchanged.
class SkyPainter extends CustomPainter {
  final SkyController c;
  final List<Path> _hills = [];
  Size _hillSize = Size.zero;

  SkyPainter(this.c) : super(repaint: c);

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    if (W <= 0 || H <= 0) return;
    final cur = c.curSafe;
    final dk = c.inputs.isDark;
    final reduce = c.inputs.reduceMotion;
    final ph = c.phase;

    // ---- static layer: gradient ----
    final grad = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, H * .85),
        [cur[0], cur[1]],
      );
    canvas.drawRect(Offset.zero & size, grad);

    // ---- static layer: hills ----
    final far = dk ? const Color(0xFF04050D) : const Color(0xFF403A70);
    if (_hills.isEmpty || _hillSize != size) _buildHills(size);
    for (int l = 0; l < 5; l++) {
      canvas.drawPath(
        _hills[l],
        Paint()..color = mixColor(cur[1], far, .12 + .17 * l),
      );
    }

    // ---- stars (night) ----
    final rain = c.E2;
    if (dk) {
      final p = Paint()..color = const Color(0xFFFFFFFF);
      for (final s in c.stars) {
        p.color = const Color(0xFFFFFFFF)
            .withOpacity((.35 + .25 * sin(ph * .7 + s.s)).clamp(0, 1) * (1 - rain));
        canvas.drawCircle(Offset(s.x * W, s.y * H), s.r, p);
      }
    }

    // ---- sun / moon ----
    final ng = c.inputs.night;
    final Rr = min(W, H) * (ng ? .045 : .065);
    final col = ng ? const Color(0xFFF6F4FF) : const Color(0xFFFFEEC4);
    final hr = Rr * (5 + c.flash * 2);
    final sx = c.sunX, sy = c.sunY;
    final halo = Paint()
      ..shader = ui.Gradient.radial(
        Offset(sx, sy),
        hr,
        [
          col.withOpacity(min(1, .5 * (1 - rain * .7) + c.flash * .3)),
          col.withOpacity(0),
        ],
        [0, 1],
      );
    canvas.drawCircle(Offset(sx, sy), hr, halo);
    canvas.drawCircle(Offset(sx, sy), Rr, Paint()..color = col.withOpacity(.9 * (1 - rain * .8)));

    // ---- waves ----
    if (c.E3 > .02) _waves(canvas, size, c.E3);

    // ---- scene art ----
    _sceneArt(canvas, size, dk);

    if (!reduce) {
      // ---- rain ----
      if (rain > .02) {
        final n = (rain * 150).round();
        final stroke = Paint()
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round
          ..color = mixColor(cur[0], dk ? const Color(0xFFFFFFFF) : const Color(0xFF28325A), .55);
        for (int i = 0; i < n && i < c.drops.length; i++) {
          final q = c.drops[i];
          q.y += q.v * c.lastDt / H;
          q.x += q.v * c.lastDt * .1 / W;
          if (q.y > 1.06) {
            q.y = -.06;
            q.x = _rnd();
          }
          if (q.x > 1.06) q.x -= 1.12;
          stroke.color = stroke.color.withOpacity(q.a * rain);
          canvas.drawLine(Offset(q.x * W, q.y * H), Offset(q.x * W - q.l * .12, q.y * H - q.l), stroke);
        }
      }

      // ---- hearth glow ----
      if (c.E6 > .02) {
        final g = Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, H),
            Offset(0, H * .5),
            [
              const Color(0xFFFF963C).withOpacity((.1 + .05 * sin(ph * 2.3)) * c.E6 * 3),
              const Color(0xFFFF963C).withOpacity(0),
            ],
          );
        canvas.drawRect(Offset.zero & size, g);
      }

      // ---- embers / fireflies ----
      for (final q in c.vps) {
        if (c.E6 > .05) {
          q.y -= (.03 + .05 * q.k) * c.lastDt;
          if (q.y < -.05) {
            q.y = 1.05;
            q.x = _rnd();
          }
          final p = Paint()
            ..color = const Color(0xFFFFAA50).withOpacity(.6 * c.E6 * (.5 + .5 * sin(ph * 3 + q.s)));
          canvas.drawCircle(Offset(q.x * W + sin(ph * .8 + q.s) * 8, q.y * H), 1.3 * q.r, p);
        } else if (ng && c.E5 > .05) {
          q.x += cos(ph * .2 + q.s) * .006 * c.lastDt;
          q.y += sin(ph * .17 + q.s) * .006 * c.lastDt;
          final a = pow(.5 + .5 * sin(ph * .9 * q.k + q.s), 3) * c.E5 * .9;
          canvas.drawCircle(Offset(q.x * W, q.y * H), 7 * q.r, Paint()..color = const Color(0xFFDCFF96).withOpacity((a * .25).clamp(0, 1)));
          canvas.drawCircle(Offset(q.x * W, q.y * H), 2, Paint()..color = const Color(0xFFEBFFAA).withOpacity(a.clamp(0, 1)));
        }
      }

      // ---- mist ----
      final mistCol = mixColor(cur[1], const Color(0xFFFFFFFF), .5);
      for (final m in c.mists) {
        m.y += m.v * c.lastDt;
        m.x += (.003 + c.E4 * .04) * c.lastDt;
        if (m.y < -.05) {
          m.y = 1.05;
          m.x = _rnd();
        }
        if (m.x > 1.05) m.x = -.05;
        canvas.drawCircle(Offset(m.x * W, m.y * H), m.r, Paint()..color = mistCol.withOpacity(m.a));
      }
    }

    // ---- breathing circle ----
    if (c.inputs.breatheOn) _breathe(canvas, size);
  }

  void _buildHills(Size size) {
    _hills.clear();
    _hillSize = size;
    final W = size.width, H = size.height;
    final step = max(8.0, 10.0);
    for (int l = 0; l < 5; l++) {
      final by = H * (.52 + l * .085);
      final am = H * (.07 + .02 * l);
      final path = Path()..moveTo(0, H);
      for (double px = 0; px <= W + step; px += step) {
        final u = px;
        final y = by -
            (sin(u * .0021 + l * 5.3) * .5 + sin(u * .0057 + l * 2.1) * .28 + sin(u * .0131 + l * 9) * .1) * am;
        path.lineTo(px, y);
      }
      path.lineTo(W, H);
      path.close();
      _hills.add(path);
    }
  }

  void _waves(Canvas canvas, Size size, double v) {
    final W = size.width, H = size.height;
    final cur = c.curSafe;
    final ph = c.phase;
    for (int l = 0; l < 3; l++) {
      final am = (18 + l * 18) * v;
      final yb = H * (.8 + l * .055);
      final sp = .5 + l * .24;
      final path = Path()..moveTo(0, H);
      final step = max(8.0, 10.0);
      for (double px = 0; px <= W; px += step) {
        final u = px;
        path.lineTo(px, yb + sin(u / 122 + ph * sp + l) * am + sin(u / 46 - ph * sp * .6) * am * .4);
      }
      path.lineTo(W, H);
      path.close();
      canvas.drawPath(path, Paint()..color = mixColor(cur[0], const Color(0xFFFFFFFF), .35).withOpacity((.12 + .1 * v).clamp(0, 1)));
    }
  }

  // -------------------------------------------------------------------------
  // Scene art — ART{ dawn, sea, woods, deep, hearth, rain }
  // -------------------------------------------------------------------------
  void _sceneArt(Canvas canvas, Size size, bool dk) {
    final cur = c.curSafe;
    final W = size.width, H = size.height;
    final tm = c.tm;
    final sx = c.sunX, sy = c.sunY;

    final dawn = c.sceneLevel('dawn');
    if (dawn > .02) {
      final r = max(W, H) * 1.3;
      final p = Paint()..color = const Color(0xFFFFD6AA).withOpacity((.06 * dawn).clamp(0, 1));
      for (int i = 0; i < 12; i++) {
        final a = i * .524 + tm * .03;
        final path = Path()
          ..moveTo(sx, sy)
          ..lineTo(sx + cos(a - .09) * r, sy + sin(a - .09) * r)
          ..lineTo(sx + cos(a + .09) * r, sy + sin(a + .09) * r)
          ..close();
        canvas.drawPath(path, p);
      }
    }

    final sea = c.sceneLevel('sea');
    if (sea > .02) {
      final y = H * .8;
      for (int i = 0; i < 16; i++) {
        final w = W * (.04 + .012 * (16 - i)) * (.7 + .3 * sin(tm * 1.7 + i * 1.3));
        canvas.drawRect(
          Rect.fromLTWH(sx - w / 2, y + i * H * .011, w, max(1, 1.5)),
          Paint()..color = const Color(0xFFFFFFFF).withOpacity((.14 * sea * (1 - i / 18)).clamp(0, 1)),
        );
      }
    }

    final woods = c.sceneLevel('woods');
    if (woods > .02) {
      canvas.drawRect(Offset.zero & size, Paint()..color = mixColor(cur[1], const Color(0xFF081C12), .6).withOpacity((.92 * woods).clamp(0, 1)));
      final tp = Paint()..color = mixColor(cur[1], const Color(0xFF081C12), .6).withOpacity((.95 * woods).clamp(0, 1));
      for (final t in c.trees) {
        final bx = t.x * W, w = t.w * W, h = t.h * H;
        for (int k = 0; k < 3; k++) {
          final yy = H - h * k * .3, ww = w * (1 - k * .22);
          final path = Path()
            ..moveTo(bx - ww, yy)
            ..lineTo(bx, yy - h * .5)
            ..lineTo(bx + ww, yy)
            ..close();
          canvas.drawPath(path, tp);
        }
      }
      for (int i = 0; i < 3; i++) {
        final x = W * (.15 + i * .3) + sin(tm * .2 + i) * W * .03;
        final g = Paint()
          ..shader = ui.Gradient.linear(
            Offset(x, 0),
            Offset(x + W * .2, H * .7),
            [const Color(0xFFFFF0BE).withOpacity((.1 * woods).clamp(0, 1)), const Color(0xFFFFF0BE).withOpacity(0)],
          );
        final path = Path()
          ..moveTo(x, 0)
          ..lineTo(x + W * .07, 0)
          ..lineTo(x + W * .3, H * .8)
          ..lineTo(x + W * .17, H * .8)
          ..close();
        canvas.drawPath(path, g);
      }
    }

    final deep = c.sceneLevel('deep');
    if (deep > .02) {
      const cols = [Color(0xFF6EFFC8), Color(0xFF9678FF), Color(0xFF5AC8FF)];
      for (int i = 0; i < 3; i++) {
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = H * (.05 + .02 * i)
          ..color = cols[i].withOpacity((.09 * deep).clamp(0, 1));
        final path = Path();
        bool first = true;
        for (double x = 0; x <= W; x += 16) {
          final y = H * (.2 + .09 * i) + sin(x / 170 + tm * .25 + i * 2) * H * .05 + sin(x / 60 + tm * .5) * H * .012;
          if (first) {
            path.moveTo(x, y);
            first = false;
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, stroke);
      }
    }

    final hearth = c.sceneLevel('hearth');
    if (hearth > .02) {
      final g = Paint()
        ..shader = ui.Gradient.radial(
          Offset(W / 2, H * .5),
          H * .9,
          [const Color(0x00000000), const Color(0xFF1E0A00).withOpacity((.35 * hearth).clamp(0, 1))],
          [.22, 1],
        );
      canvas.drawRect(Offset.zero & size, g);
      for (int i = 0; i < 5; i++) {
        final cx = W * (.5 + (i - 2) * .06);
        final w = W * .035;
        final h = H * (.13 + .04 * sin(tm * 3.1 + i * 2.2) + (i == 2 ? .05 : 0));
        final f = Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, H),
            Offset(0, H - h),
            [const Color(0xFFFF7828).withOpacity((.55 * hearth).clamp(0, 1)), const Color(0xFFFFC85A).withOpacity(0)],
          );
        final path = Path()
          ..moveTo(cx - w, H)
          ..quadraticBezierTo(cx - w * .3, H - h * .55, cx + sin(tm * 4 + i) * w * .5, H - h)
          ..quadraticBezierTo(cx + w * .3, H - h * .5, cx + w, H)
          ..close();
        canvas.drawPath(path, f);
      }
    }

    final rainArt = c.sceneLevel('rain');
    if (rainArt > .02) {
      for (int i = 0; i < 3; i++) {
        final x = ((tm * (6 + i * 3) + i * W * .4) % (W * 1.5)) - W * .25;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, H * (.55 + .12 * i)), width: W, height: H * .14),
          Paint()..color = const Color(0xFFFFFFFF).withOpacity((.07 * rainArt).clamp(0, 1)),
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // Breathing circle
  // -------------------------------------------------------------------------
  void _breathe(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    final cur = c.curSafe;
    final P = breathePattern(c.inputs.breatheKind);
    final tot = P.fold<double>(0, (a, b) => a + b.len);
    double t = c.inputs.breatheTime % tot;
    int i = 0;
    while (t >= P[i].len) {
      t -= P[i].len;
      i++;
    }
    final ph = P[i];
    final f = t / ph.len;
    final e = f * f * (3 - 2 * f);
    final sc = ph.kind == 'i'
        ? e
        : ph.kind == 'o'
            ? 1 - e
            : (P[(i + P.length - 1) % P.length].kind == 'i' ? 1.0 : 0.0);
    final cx = W / 2, cy = H * .42;
    final r = min(W, H) * (.1 + .17 * sc);
    final g = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        r * 1.9,
        [cur[2].withOpacity(.5), cur[2].withOpacity(0)],
        [.105, 1],
      );
    canvas.drawCircle(Offset(cx, cy), r * 1.9, g);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = cur[2].withOpacity(.75),
    );
  }

  @override
  bool shouldRepaint(covariant SkyPainter oldDelegate) => false;

  static final Random _rr = Random();
  static double _rnd() => _rr.nextDouble();
}

// ---------------------------------------------------------------------------
// Breathing patterns — BP{ box, r478, even }
// ---------------------------------------------------------------------------
class BreathPhase {
  final String label; // "Breathe in" / "Hold" / "Breathe out"
  final double len; // seconds
  final String kind; // 'i' | 'h' | 'o'
  const BreathPhase(this.label, this.len, this.kind);
}

class BreathPattern {
  final String name;
  final List<BreathPhase> phases;
  const BreathPattern(this.name, this.phases);
}

const Map<String, BreathPattern> kBreathPatterns = {
  'box': BreathPattern('Box 4-4-4-4', [
    BreathPhase('Breathe in', 4, 'i'),
    BreathPhase('Hold', 4, 'h'),
    BreathPhase('Breathe out', 4, 'o'),
    BreathPhase('Hold', 4, 'h'),
  ]),
  'r478': BreathPattern('4-7-8', [
    BreathPhase('Breathe in', 4, 'i'),
    BreathPhase('Hold', 7, 'h'),
    BreathPhase('Breathe out', 8, 'o'),
  ]),
  'even': BreathPattern('Even 5-5', [
    BreathPhase('Breathe in', 5, 'i'),
    BreathPhase('Breathe out', 5, 'o'),
  ]),
};

List<BreathPhase> breathePattern(String key) => (kBreathPatterns[key] ?? kBreathPatterns['box']!).phases;
