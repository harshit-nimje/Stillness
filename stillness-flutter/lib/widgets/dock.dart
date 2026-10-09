import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/type.dart';
import '../state/app_state.dart';
import '../state/audio.dart';
import '../state/breathe.dart';
import '../state/focus.dart';
import '../theme/theme_scope.dart';
import 'glass.dart';
import 'icons.dart';

/// The floating bottom navigation dock. Mirrors `dockUI()`: the Sound button
/// lights up while audio plays (and shows the scene / track name), the Focus
/// button lights while a session runs (and shows the countdown), Breathe lights
/// while breathing, and the active button carries a pulsing accent dot.
class Dock extends StatelessWidget {
  const Dock({
    super.key,
    required this.onSound,
    required this.onLife,
    required this.onSettings,
  });

  final VoidCallback onSound;
  final VoidCallback onLife;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final app = context.watch<AppState>();
    final audio = context.watch<AudioController>();
    final focus = context.watch<FocusController>();
    final breathe = context.watch<BreatheController>();

    final soundOn = audio.on || audio.libOn;
    final focusOn = focus.run;
    final breatheOn = breathe.on;

    return Glass(
      palette: p,
      radius: Tokens.rPill,
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DockButton(
            icon: Icons24.sound,
            label: soundOn ? audio.dockLabel : 'Sound',
            on: soundOn,
            onTap: onSound,
          ),
          _DockButton(
            icon: Icons24.focus,
            label: focusOn ? FocusController.fmt(focus.left) : 'Focus',
            on: focusOn,
            active: focus.open,
            onTap: () => focus.open ? focus.closeStage() : focus.openStage(focus.taskId),
          ),
          _DockButton(
            icon: Icons24.breathe,
            label: 'Breathe',
            on: breatheOn,
            onTap: () => breathe.setBreath(!breathe.on),
          ),
          _DockButton(icon: Icons24.life, label: 'Life', on: false, onTap: onLife),
          _DockButton(icon: Icons24.settings, label: 'Settings', on: false, onTap: onSettings),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
    this.active = false,
  });

  final String icon;
  final String label;
  final bool on;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final lit = on || active;
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 56,
        decoration: BoxDecoration(
          color: lit ? p.hov : const Color(0x00000000),
          borderRadius: BorderRadius.circular(Tokens.rPill),
        ),
        child: Stack(
          children: [
            if (on) const Positioned(top: 8, right: 13, child: _PulseDot()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  svgStroke(icon, color: lit ? p.ink : p.ink2, size: 22, strokeWidth: 1.5),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 56,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Type.sans(size: 12, color: lit ? p.ink : p.ink2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: .35).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: p.ac, shape: BoxShape.circle),
      ),
    );
  }
}
