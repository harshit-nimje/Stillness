import 'package:flutter/material.dart';

import '../core/type.dart';
import '../sky/sky.dart';
import '../theme/theme_scope.dart';
import 'icons.dart';

/// The animated logo. Its mark and tagline change with the playing scene
/// (`LG` / `LT`), and the default mark carries the expanding ripple rings.
class Logo extends StatelessWidget {
  const Logo({super.key, this.sceneKey});

  final String? sceneKey;

  static const _marks = <String, String>{
    '': '<circle cx="16" cy="16" r="2.5"/>'
        '<circle cx="16" cy="16" r="9"/>'
        '<circle cx="16" cy="16" r="13"/>',
    'dawn': '<path d="M3 22h26M8 22a8 8 0 0116 0M16 6v3M6 11l2 2M26 11l-2 2"/><path d="M9 27h14"/>',
    'rain': '<path d="M16 4c4 6 6 9 6 12a6 6 0 01-12 0c0-3 2-6 6-12z"/><path d="M5 28q5-3 10 0t12 0"/>',
    'sea': '<path d="M3 12q3.25-3 6.5 0t6.5 0t6.5 0t6.5 0M3 19q3.25-3 6.5 0t6.5 0t6.5 0t6.5 0M3 26q3.25-3 6.5 0t6.5 0t6.5 0t6.5 0"/>',
    'woods': '<path d="M16 3l6 9h-3.5l5.5 8H8l5.5-8H10z"/><path d="M16 20v9"/>',
    'hearth': '<path d="M16 3c1 5 7 8 7 15a7 7 0 01-14 0c0-4 2-5 3-8 1 2 2 3 4 3-1-4-1-7 0-10z"/>',
    'deep': '<path d="M21 5a11 11 0 100 22 9 9 0 01-4-11 9 9 0 014-11z"/><path d="M26 6v4M24 8h4"/>',
  };

  static const _taglines = <String, String>{
    'dawn': 'first light',
    'rain': 'soft rain',
    'sea': 'slow tide',
    'woods': 'deep woods',
    'hearth': 'by the fire',
    'deep': 'night depth',
  };

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final k = sceneKey ?? '';
    final body = _marks[k] ?? _marks['']!;
    final tag = _taglines[k] ?? 'be still';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 0),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (k.isEmpty) const _Ripple(),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: SvgStrokeMark(body: body, color: p.ac),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stillness', style: Type.logoTitle(p.ink)),
              const SizedBox(height: 3),
              Text(
                tag.toUpperCase(),
                style: Type.logoSmall(p.ink2).copyWith(letterSpacing: 10.5 * .2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Static stroke mark rendered through flutter_svg at viewBox 0 0 32 32.
class SvgStrokeMark extends StatelessWidget {
  const SvgStrokeMark({super.key, required this.body, required this.color});
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => svgStroke(
        body,
        color: color,
        size: 32,
        strokeWidth: 1.5,
        viewBox: '0 0 32 32',
      );
}

/// The `rp` ripple rings on the default mark — two circles expanding and
/// fading on a 4.5s loop.
class _Ripple extends StatefulWidget {
  const _Ripple();
  @override
  State<_Ripple> createState() => _RippleState();
}

class _RippleState extends State<_Ripple> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        size: const Size(36, 36),
        painter: _RipplePainter(_c.value, p.ac),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double t;
  final Color color;
  _RipplePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (final delay in [0.0, 1.5 / 4.5]) {
      final u = ((t + delay) % 1.0);
      final scale = .35 + u * .85;
      final opacity = (.9 * (1 - u)).clamp(0, 1);
      canvas.drawCircle(
        c,
        scale * 13,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.t != t || old.color != color;
}
