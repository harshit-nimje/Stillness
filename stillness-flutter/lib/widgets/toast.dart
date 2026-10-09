import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/type.dart';
import '../state/app_state.dart';
import '../theme/theme_scope.dart';

/// The transient notification (`#say`) — a glass pill at the top of the
/// screen with an optional inline action. Slides down from -14px and fades.
class ToastLayer extends StatelessWidget {
  const ToastLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = ThemeScope.of(context);
    final msg = app.toast.value;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Tokens.ease,
          switchOutCurve: Tokens.ease,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -.25), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: msg == null
              ? const SizedBox.shrink(key: ValueKey('none'))
              : Padding(
                  key: ValueKey(msg.id),
                  padding: const EdgeInsets.only(top: 14),
                  child: Center(
                    child: _Pill(msg: msg, palette: p),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.msg, required this.palette});
  final ToastMsg msg;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.rPill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .9),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: p.glass,
            borderRadius: BorderRadius.circular(Tokens.rPill),
            border: Border.all(color: p.edge, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  msg.text,
                  style: Type.serif(size: 1.15 * 16, wght: 400, italic: true, color: p.ink),
                ),
              ),
              if (msg.actionLabel != null) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: msg.onAction,
                  child: Text(
                    msg.actionLabel!,
                    style: Type.sans(size: 13, wght: 600, color: p.ink).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: p.ink,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
