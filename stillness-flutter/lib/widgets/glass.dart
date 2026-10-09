import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../core/tokens.dart';

/// Glass surface — `.glass` in the CSS: translucent fill, 1px light edge,
/// 22px backdrop blur with 140% saturation, and the soft 30/60/-36 shadow.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.palette,
    this.radius = 0,
    this.padding = EdgeInsets.zero,
    this.border = true,
    this.blur = true,
  });

  final Widget child;
  final Palette? palette;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool border;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? const Palette(
      top: Color(0xFFBCD0EE),
      bot: Color(0xFFE6EEF7),
      ac: Color(0xFF4A63B8),
      ink: Tokens.lightInk,
      ink2: Tokens.lightInk2,
      line: Tokens.lightLine,
      glass: Tokens.lightGlass,
      sheet: Tokens.lightSheet,
      edge: Tokens.lightEdge,
      shade: Tokens.lightShade,
      hov: Tokens.lightHov,
      isDark: false,
    );

    Widget content = Padding(padding: padding, child: child);

    if (blur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: Tokens.glassBlur * 0.55,
            sigmaY: Tokens.glassBlur * 0.55,
          ),
          child: content,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: p.edge, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: p.shade,
            blurRadius: 60,
            spreadRadius: -36,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: content,
    );
  }
}
