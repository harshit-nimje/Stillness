import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/type.dart';
import '../state/app_state.dart';
import '../state/audio.dart';
import '../state/onboarding.dart';
import '../theme/theme_scope.dart';
import '../widgets/controls.dart';
import '../widgets/icons.dart';

/// The onboarding overlay — `#ob`. Nine pages (or four in replay), each with an
/// illustration, dots, Skip intro, Back and Continue.
class OnboardingOverlay extends StatelessWidget {
  const OnboardingOverlay({super.key, required this.onClose, required this.onFinish});

  final VoidCallback onClose;
  final void Function(bool skip) onFinish;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final ob = context.watch<OnboardingController>();
    final audio = context.read<AudioController>();
    final pages = ob.rep == 1 ? 4 : 9;

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.transparent,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460, maxHeight: MediaQuery.sizeOf(context).height - 32),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                decoration: BoxDecoration(
                  color: p.sheet,
                  borderRadius: BorderRadius.circular(Tokens.rSheet),
                  border: Border.all(color: p.edge, width: 1),
                  boxShadow: [BoxShadow(color: p.shade, blurRadius: 60, spreadRadius: -36, offset: const Offset(0, 30))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            for (int i = 0; i < pages; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Tokens.ease,
                                margin: const EdgeInsets.only(right: 6),
                                width: i == ob.i ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == ob.i ? p.ac : p.line,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                          ],
                        ),
                        if (ob.i <= 3)
                          GestureDetector(
                            onTap: () {
                              if (ob.hear) audio.stop();
                              onClose();
                            },
                            child: Text('Skip intro',
                                style: Type.sans(size: 13, color: p.ink2).copyWith(decoration: TextDecoration.underline)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Tokens.ease,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: Offset(ob.d * .18, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _page(context, ob, audio, p),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Visibility(
                          visible: ob.i > 0,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: AppButton(label: 'Back', onTap: ob.back),
                        ),
                        if (ob.i < pages - 1)
                          AppButton(
                            label: ob.i == 0
                                ? 'Begin'
                                : (ob.rep == 1 && ob.i == 3)
                                    ? 'Done'
                                    : 'Continue',
                            primary: true,
                            onTap: () {
                              if (ob.rep == 1 && ob.i == 3) {
                                onClose();
                              } else {
                                ob.next();
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _page(BuildContext context, OnboardingController ob, AudioController audio, dynamic p) {
    switch (ob.i) {
      case 0:
        return _pageWrap(context, ob.i, [
          const Illustration(kind: 'w'),
          _title('Stillness', italic: true, color: p.ink),
          _sub('A calm place to plan your day, focus, and build better habits. The sky follows your clock.', p),
        ]);
      case 1:
        return _pageWrap(context, ob.i, [
          const Illustration(kind: 'f'),
          _title('One thing at a time', color: p.ink),
          _sub('Pick a task and start a focus session. The sun crosses the sky as time passes, and rest comes built in.', p),
        ]);
      case 2:
        return _pageWrap(context, ob.i, [
          const Illustration(kind: 's'),
          _title('Sound that fits', color: p.ink),
          _sub('Generated rain, sea, woods and more. Every scene repaints the sky and redraws the logo.', p),
          const SizedBox(height: 12),
          AppButton(
            label: ob.hear ? 'Silence' : 'Hear Dawn',
            onTap: () {
              if (ob.hear) {
                audio.stop();
                ob.hear = false;
              } else {
                audio.play('dawn');
                ob.hear = true;
              }
              ob.go(ob.i, 1);
            },
          ),
        ]);
      case 3:
        return _pageWrap(context, ob.i, [
          const Illustration(kind: 'l'),
          _title('Momentum', color: p.ink),
          _sub('Habits, focus and finished tasks build a score. Every session banks time you can spend guilt-free.', p),
        ]);
      case 4:
        return _pageWrap(context, ob.i, [
          _ik(Icons24.face, p),
          _title('What should I call you?', color: p.ink),
          const SizedBox(height: 10),
          TextField(
            autofocus: true,
            maxLength: 40,
            style: Type.obInput(p.ink),
            textAlign: TextAlign.center,
            decoration: _plain(p, 'Your name'),
            onChanged: (v) {
              ob.name = v.trim();
              ob.go(ob.i, 1);
            },
          ),
          _sub(_greeting(ob.name), p),
        ]);
      case 5:
        return _pageWrap(context, ob.i, [
          _ik(Icons24.sprout, p),
          _title('What do you want to improve?', color: p.ink),
          _sub('Pick any. These become habits to build.', p),
          _chips(context, ob, ob.bl, ob.bs, 'b', p),
          _addRow(context, ob, 'b', 'Something else', p),
        ]);
      case 6:
        return _pageWrap(context, ob.i, [
          _ik(Icons24.quit, p),
          _title('What do you want to quit?', color: p.ink),
          _sub('Pick any. You will log slips, not streaks of guilt.', p),
          _chips(context, ob, ob.ql, ob.qs, 'q', p),
          _addRow(context, ob, 'q', 'Something else', p),
        ]);
      case 7:
        return _pageWrap(context, ob.i, [
          _ik(Icons24.task, p),
          _title('Your first task', color: p.ink),
          _sub('One thing that would make today good. Optional.', p),
          TextField(
            maxLength: 120,
            style: Type.obInput(p.ink),
            textAlign: TextAlign.center,
            decoration: _plain(p, 'e.g. Write the intro #work @6pm'),
            onChanged: (v) => ob.task = v,
          ),
        ]);
      default:
        return _pageWrap(context, ob.i, [
          _ik(Icons24.cloud, p),
          _title('Keep it safe', color: p.ink),
          _sub('Choose how your data is stored.', p),
          _option(context, Icons24.cloud, 'Continue with Claude', 'Private cloud sync across devices',
              onTap: () => onFinish(false), p: p),
          _option(context, Icons24.file, 'Restore a backup', 'Paste a JSON backup',
              onTap: () => _backupDialog(context), p: p),
          _option(context, Icons24.dev, 'Continue as guest', 'Saved on this device only',
              onTap: () => onFinish(false), p: p),
        ]);
    }
  }

  Future<void> _backupDialog(BuildContext context) async {
    final app = context.read<AppState>();
    final ctrl = TextEditingController();
    final p = ThemeScope.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.rOpt)),
        title: Text('Restore a backup', style: Type.h2(p.ink)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: Type.sans(size: 12, color: p.ink),
          decoration: InputDecoration(hintText: 'Paste backup JSON', hintStyle: Type.body(p.ink2)),
        ),
        actions: [
          AppButton(label: 'Cancel', onTap: () => Navigator.of(ctx).pop()),
          AppButton(
            label: 'Restore',
            primary: true,
            onTap: () {
              final ok = app.restore(ctrl.text);
              if (ok) {
                Navigator.of(ctx).pop();
                onFinish(true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _pageWrap(BuildContext context, int i, List<Widget> children) => Column(
        key: ValueKey(i),
        children: children,
      );

  Widget _title(String s, {bool italic = false, required Color color}) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(s, textAlign: TextAlign.center, style: Type.serif(size: 2 * 16, wght: 300, italic: italic, color: color)),
      );

  Widget _sub(String s, dynamic p) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 34 * 8),
          child: Text(s, textAlign: TextAlign.center, style: Type.body(p.ink2)),
        ),
      );

  Widget _ik(String body, dynamic p) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: svgStroke(body, color: p.ac, size: 60, strokeWidth: 1.4, viewBox: '0 0 32 32'),
      );

  Widget _chips(BuildContext context, OnboardingController ob, List<String> pool, Set<String> set, String k, dynamic p) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final x in pool)
              AppChip(label: x, selected: set.contains(x), onTap: () => ob.toggle(pool, set, x)),
          ],
        ),
      );

  Widget _addRow(BuildContext context, OnboardingController ob, String k, String ph, dynamic p) {
    final ctrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 3),
          decoration: BoxDecoration(
            border: Border.all(color: p.line, width: 1),
            borderRadius: BorderRadius.circular(Tokens.rPill),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLength: 40,
                  style: Type.body(p.ink),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: ph,
                    hintStyle: Type.body(p.ink2),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (v) {
                    final pool = k == 'b' ? ob.bl : ob.ql;
                    final set = k == 'b' ? ob.bs : ob.qs;
                    ob.addCustom(pool, set, v);
                    ctrl.clear();
                  },
                ),
              ),
              IconBtn(
                body: Icons24.plus,
                onTap: () {
                  final pool = k == 'b' ? ob.bl : ob.ql;
                  final set = k == 'b' ? ob.bs : ob.qs;
                  ob.addCustom(pool, set, ctrl.text);
                  ctrl.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(BuildContext context, String icon, String title, String sub, {required VoidCallback onTap, required dynamic p}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: p.hov,
            border: Border.all(color: p.line, width: 1),
            borderRadius: BorderRadius.circular(Tokens.rOpt),
          ),
          child: Row(
            children: [
              svgStroke(icon, color: p.ac, size: 34, strokeWidth: 1.4, viewBox: '0 0 32 32'),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Type.serif(size: 1.2 * 16, wght: 400, color: p.ink)),
                    Text(sub, style: Type.sans(size: 13, color: p.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _plain(dynamic p, String hint) => InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: Type.obInput(p.ink2),
        border: UnderlineInputBorder(borderSide: BorderSide(color: p.line, width: 1.5)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.ac, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      );

  String _greeting(String n) {
    final h = DateTime.now().hour;
    final g = h < 5
        ? 'Still awake'
        : h < 12
            ? 'Good morning'
            : h < 17
                ? 'Good afternoon'
                : 'Good evening';
    return n.isEmpty ? '$g.' : '$g, $n.';
  }
}

/// Onboarding illustrations (`IL.w`, `IL.f`, `IL.s`, `IL.l`) — the SMIL
/// animations from the original rebuilt with Flutter animation controllers.
class Illustration extends StatefulWidget {
  const Illustration({super.key, required this.kind});
  final String kind;

  @override
  State<Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<Illustration> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return SizedBox(
      width: 190,
      height: 190,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: _IllPainter(widget.kind, _c.value, p.ac, p.line, p.ink)),
      ),
    );
  }
}

class _IllPainter extends CustomPainter {
  final String kind;
  final double t; // 0..1 over 5s
  final Color ac;
  final Color line;
  final Color ink;
  _IllPainter(this.kind, this.t, this.ac, this.line, this.ink);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final u = size.width / 160;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * u
      ..strokeCap = StrokeCap.round
      ..color = ac;

    switch (kind) {
      case 'w':
        for (int i = 0; i < 3; i++) {
          final ph = (t * 5 / 4.5 + i * 1.5 / 4.5) % 1.0;
          canvas.drawCircle(
            c,
            (.35 + ph * .85) * 62 * u,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4 * u
              ..color = ac.withOpacity((1 - ph).clamp(0, 1)),
          );
        }
        canvas.drawCircle(c, (7 + 3 * sin(t * 2 * pi)) * u, Paint()..color = ac);
        break;
      case 'f':
        canvas.drawCircle(c, 60 * u, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * u
          ..color = line);
        final sweep = t * 2 * pi;
        canvas.drawArc(Rect.fromCircle(center: c, radius: 60 * u), -pi / 2, sweep, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * u
              ..strokeCap = StrokeCap.round
              ..color = ac);
        final a = -pi / 2 + sweep;
        canvas.drawCircle(c + Offset(cos(a), sin(a)) * 60 * u, 8 * u, Paint()..color = ac);
        final tp = TextPainter(
          text: TextSpan(text: '25:00', style: TextStyle(fontSize: 34 * u, color: ink)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
        break;
      case 's':
        canvas.drawCircle(Offset(112 * u, 42 * u), 15 * u, Paint()..color = ac.withOpacity(.5));
        for (int i = 0; i < 3; i++) {
          final y = (98 + i * 18) * u;
          final shift = -((t * 5 * (20 + i * 6)) % 40) * u;
          final path = Path();
          bool first = true;
          for (double x = -40 * u; x <= size.width + 40 * u; x += 8 * u) {
            final yy = y + sin((x - shift) / (20 * u)) * 6 * u;
            if (first) {
              path.moveTo(x, yy);
              first = false;
            } else {
              path.lineTo(x, yy);
            }
          }
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6 * u
              ..strokeCap = StrokeCap.round
              ..color = ac.withOpacity([.4, .7, 1][i]),
          );
        }
        for (int i = 0; i < 4; i++) {
          final ph = (t * 5 / 2.2 + i * .5) % 1.0;
          final x = (30 + i * 22) * u;
          final y = (10 + ph * 40) * u;
          canvas.drawLine(Offset(x, y), Offset(x, y + 8 * u),
              Paint()..strokeWidth = 1.6 * u..strokeCap = StrokeCap.round..color = ac.withOpacity((1 - ph).clamp(0, 1)));
        }
        break;
      default: // l
        const bars = [20.0, 34, 28, 50, 44, 70, 92];
        for (int i = 0; i < 7; i++) {
          final ph = ((t * 3.6 + i * .12) % 1.0);
          final scale = ph < .35 ? ph / .35 : (ph < .85 ? 1 : (1 - (ph - .85) / .15));
          final h = bars[i] * scale.clamp(0, 1) * u;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH((14 + i * 20) * u, (130 * u) - h, 12 * u, h),
              Radius.circular(6 * u),
            ),
            Paint()..color = ac,
          );
        }
        canvas.drawCircle(Offset(40 * u, 40 * u + sin(t * 2 * pi) * 6 * u), 18 * u,
            Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6 * u..color = ac);
        final tp = TextPainter(
          text: TextSpan(text: '+5', style: TextStyle(fontSize: 16 * u, color: ink)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(40 * u - tp.width / 2, 40 * u - tp.height / 2 + sin(t * 2 * pi) * 6 * u));
    }
  }

  @override
  bool shouldRepaint(covariant _IllPainter old) => old.t != t || old.kind != kind;
}
