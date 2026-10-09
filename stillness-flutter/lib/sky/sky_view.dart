import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/audio.dart';
import '../state/breathe.dart';
import '../state/focus.dart';
import 'sky.dart';
import 'sky_painter.dart';

/// Hosts the sky canvas. A [Ticker] advances the [SkyController] each frame and
/// the [CustomPainter] repaints via the controller's listenable — the widget
/// tree is never rebuilt for the animation. The Ticker is muted by the engine
/// when the app is not visible, so backgrounding costs nothing.
class SkyView extends StatefulWidget {
  const SkyView({super.key});

  @override
  State<SkyView> createState() => _SkyViewState();
}

class _SkyViewState extends State<SkyView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late SkyController _sky;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sky = context.read<SkyController>();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final focus = context.read<FocusController>();
    final breathe = context.read<BreatheController>();
    final audio = context.read<AudioController>();
    final app = context.read<AppState>();
    final now = DateTime.now();

    _sky.inputs
      ..isDark = app.isDark(now)
      ..night = AppState.isNight(now)
      ..tint = audio.tint
      ..soundOn = audio.on
      ..sceneKey = audio.key.isEmpty ? null : audio.key
      ..mix = audio.mix
      ..focusProgress = focus.progress
      ..breatheOn = breathe.on
      ..breatheKind = breathe.kind
      ..breatheTime = breathe.elapsedSeconds
      ..reduceMotion = app.reduceMotion;

    _sky.tick(elapsed.inMilliseconds);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _sky.size = Size(constraints.maxWidth, constraints.maxHeight);
          return CustomPaint(
            painter: SkyPainter(_sky),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          );
        },
      ),
    );
  }
}
