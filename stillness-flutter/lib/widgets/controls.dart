import 'dart:math';

import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/type.dart';
import '../theme/theme_scope.dart';
import 'icons.dart';

/// A pressable that scales to .95 on press — the shared `:active` behaviour.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap, this.scale = .95});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 150),
        curve: Tokens.ease,
        child: widget.child,
      ),
    );
  }
}

/// `.btn` / `.pri` — the pill button.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final bg = primary ? p.ink : p.hov;
    final fg = primary ? p.bot : p.ink;
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: PressScale(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Tokens.rPill),
            border: Border.all(color: primary ? p.ink : p.line, width: 1),
          ),
          child: Text(label, style: Type.sans(size: 15, wght: 500, color: fg)),
        ),
      ),
    );
  }
}

/// `.chip` — small pill toggle.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.ink : const Color(0x00000000),
          borderRadius: BorderRadius.circular(Tokens.rPill),
          border: Border.all(color: selected ? p.ink : p.line, width: 1),
        ),
        child: Text(label, style: Type.sans(size: 13, color: selected ? p.bot : p.ink)),
      ),
    );
  }
}

/// `.ib` — a 36px round icon button.
class IconBtn extends StatelessWidget {
  const IconBtn({super.key, required this.body, this.onTap, this.size = 36, this.iconSize = 18, this.color});

  final String body;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return PressScale(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: svgStroke(body, color: color ?? p.ink, size: iconSize, strokeWidth: 1.6)),
      ),
    );
  }
}

/// `.sc` — a scene button in the 3-column grid.
class SceneButton extends StatelessWidget {
  const SceneButton({
    super.key,
    required this.name,
    required this.color,
    required this.selected,
    this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? p.ink : const Color(0x00000000),
          borderRadius: BorderRadius.circular(Tokens.rScene),
          border: Border.all(color: selected ? p.ink : p.line, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(height: 6),
            Text(name, style: Type.sceneChip(selected ? p.bot : p.ink)),
          ],
        ),
      ),
    );
  }
}

/// `.sl` — a labelled slider row (96px label column).
class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.trailing,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Row(
              children: [
                Flexible(child: Text(label, style: Type.body(p.ink))),
                if (trailing != null) ...[const SizedBox(width: 4), trailing!],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: p.ac,
                inactiveTrackColor: p.line,
                thumbColor: p.ac,
                overlayColor: p.ac.withOpacity(.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dial` — the focus progress ring (r=46 in a 100 box, dasharray 289).
class FocusDial extends StatelessWidget {
  const FocusDial({super.key, required this.progress, required this.child});

  /// 0..1
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DialPainter(progress: progress, track: p.line, accent: p.ac)),
          ),
          child,
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color accent;
  _DialPainter({required this.progress, required this.track, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * .46;
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * .007;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, r, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: r);
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = accent;
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0, 1), false, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.progress != progress || old.track != track || old.accent != accent;
}
