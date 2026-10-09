import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/type.dart';
import '../models/stillness_data.dart';
import '../state/app_state.dart';
import '../theme/theme_scope.dart';
import 'controls.dart';
import 'icons.dart';

/// A single task row — `.t` in the CSS. Handles the rising entrance, the
/// animated strike-through, the drawing check, the metadata line, and the
/// hover/touch action cluster.
class TaskRow extends StatefulWidget {
  const TaskRow({super.key, required this.task, this.isFresh = false, this.habit = false});

  final TaskItem task;
  final bool isFresh;
  /// habit rows share the row look but drop the strike and swap the actions.
  final bool habit;

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  bool _editing = false;
  late final TextEditingController _ctrl = TextEditingController(text: widget.task.title);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _ctrl.text = widget.task.title;
    });
  }

  void _commit(bool ok) {
    if (!_editing) return;
    final app = context.read<AppState>();
    setState(() => _editing = false);
    if (ok) app.updateTask(widget.task, _ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final app = context.read<AppState>();
    final t = widget.task;
    final done = t.done && !widget.habit;

    Widget row = Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Check(
            done: done,
            palette: p,
            onTap: () {
              if (widget.habit) return;
              if (t.done) {
                app.uncomplete(t);
              } else {
                app.complete(t);
              }
            },
          ),
          const SizedBox(width: 14),
          Expanded(child: _body(app, p, done)),
          if (!done && !widget.habit) _actions(app, p),
        ],
      ),
    );

    if (widget.isFresh) {
      row = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Tokens.ease,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
        ),
        child: row,
      );
    }

    return row;
  }

  Widget _body(AppState app, Palette p, bool done) {
    final t = widget.task;
    if (_editing) {
      return TextField(
        controller: _ctrl,
        autofocus: true,
        maxLength: 120,
        maxLines: 1,
        cursorColor: p.ac,
        style: Type.taskText(p.ink),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.only(bottom: 2),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.ac, width: 1.5)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.ac, width: 1.5)),
        ),
        onSubmitted: (_) => _commit(true),
        onTapOutside: (_) => _commit(true),
      );
    }

    final meta = <Widget>[];
    if (t.tag != null) {
      meta.add(GestureDetector(
        onTap: () => app.toggleScope(t.tag!),
        child: Text(
          '#${t.tag}',
          style: Type.meta(p.ink).copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
          ),
        ),
      ));
    }
    if (t.due != null) meta.add(Text('at ${t.due}', style: Type.meta(p.ink2)));
    if (t.rec != null) meta.add(Text('repeats ${t.rec == 'd' ? 'daily' : 'weekly'}', style: Type.meta(p.ink2)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: (!done && !widget.habit) ? _startEdit : null,
          child: StrikeText(
            text: t.title,
            style: Type.taskText(p.ink).copyWith(color: done ? p.ink.withOpacity(.5) : p.ink),
            struck: done,
            lineColor: p.ink,
          ),
        ),
        if (meta.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(spacing: 12, runSpacing: 4, children: meta),
          ),
      ],
    );
  }

  Widget _actions(AppState app, Palette p) {
    return Opacity(
      opacity: .7,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBtn(body: Icons24.foc, onTap: () => app.onFocusTask?.call(widget.task)),
          IconBtn(body: Icons24.up, onTap: () => app.pinTask(widget.task)),
          IconBtn(body: Icons24.del, onTap: () => app.removeTask(widget.task)),
        ],
      ),
    );
  }
}

/// The circular checkbox with a drawing check (`stroke-dashoffset`).
class _Check extends StatelessWidget {
  const _Check({required this.done, required this.palette, required this.onTap});
  final bool done;
  final Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: done ? p.ac : const Color(0x00000000),
          shape: BoxShape.circle,
          border: Border.all(color: done ? p.ac : p.ink2, width: 1.5),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: done ? 0 : 0, end: done ? 1 : 0),
            duration: const Duration(milliseconds: 500),
            curve: const Interval(.1, 1, curve: Tokens.ease),
            builder: (_, v, __) => CustomPaint(
              size: const Size(16, 16),
              painter: _CheckPainter(v, const Color(0xFFFFFFFF)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CheckPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    // path "M6.5 12.5l3.5 3.5 7.5-8" scaled from 24 to `size`
    final s = size.width / 24;
    final path = Path()
      ..moveTo(6.5 * s, 12.5 * s)
      ..lineTo(10 * s, 16 * s)
      ..lineTo(17.5 * s, 8 * s);
    final metric = path.computeMetrics().first;
    final extract = metric.extractPath(0, metric.length * progress.clamp(0, 1));
    canvas.drawPath(
      extract,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}

/// Text with an animated strike-through that grows from the left.
class StrikeText extends StatelessWidget {
  const StrikeText({super.key, required this.text, required this.style, required this.struck, required this.lineColor});

  final String text;
  final TextStyle style;
  final bool struck;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: null,
        textDirection: Directionality.of(context),
      )..layout(maxWidth: constraints.maxWidth);
      return Stack(
        children: [
          Text(text, style: style),
          Positioned(
            left: 0,
            top: tp.height * .6,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: struck ? 1 : 0),
              duration: const Duration(milliseconds: 700),
              curve: Tokens.easeStrike,
              builder: (_, v, __) => Container(width: tp.width * v, height: 1.5, color: lineColor),
            ),
          ),
        ],
      );
    });
  }
}
