import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../theme/theme_scope.dart';

/// Opens a Stillness bottom sheet — the native equivalent of the HTML
/// `<dialog class="sheet glass">`. Rise-in (.4s), sink-out (.22s), a dimmed
/// and blurred backdrop, bottom-anchored, and full-width on phones.
Future<T?> showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierColor: null,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionsBuilder: (c, anim, sec, _) {
        final eased = CurvedAnimation(parent: anim, curve: Tokens.ease, reverseCurve: Curves.easeIn);
        return Stack(
          children: [
            // backdrop: rgba(12,10,34,.3) + blur(10)
            FadeTransition(
              opacity: anim,
              child: GestureDetector(
                onTap: () => Navigator.of(c).maybePop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: const Color(0x4D0C0A22)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(eased),
                child: FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .98, end: 1).animate(eased),
                    child: builder(c),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// The glass panel every sheet lives in.
class SheetShell extends StatelessWidget {
  const SheetShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = ThemeScope.of(context);
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final mobile = w <= Tokens.maxWidth;

    final radius = mobile
        ? const BorderRadius.only(
            topLeft: Radius.circular(Tokens.rSheet),
            topRight: Radius.circular(Tokens.rSheet),
          )
        : BorderRadius.circular(Tokens.rSheet);

    return Padding(
      padding: EdgeInsets.only(bottom: mobile ? 0 : 24),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: mobile ? w : w.clamp(0, 480),
            constraints: BoxConstraints(maxHeight: mq.size.height * (mobile ? .90 : .88)),
            decoration: BoxDecoration(
              color: p.sheet,
              borderRadius: radius,
              border: Border.all(color: p.edge, width: 1),
              boxShadow: [
                BoxShadow(color: p.shade, blurRadius: 60, spreadRadius: -36, offset: const Offset(0, 30)),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(26, 28, 26, 28 + (mobile ? mq.padding.bottom : 0)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
