import 'dart:ui' show FontVariation;

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Typography, ported from the CSS. Both families are bundled as variable
/// fonts, so weight and optical size are applied through `FontVariation`
/// exactly as the browser applied `font-weight` / `font-optical-sizing`.
class Type {
  const Type._();

  static TextStyle serif({
    double size = 15,
    double wght = 400,
    bool italic = false,
    double height = 1.5,
    double ls = 0,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: Tokens.serif,
        fontFamilyFallback: const ['Georgia', 'serif'],
        fontSize: size,
        height: height,
        letterSpacing: ls == 0 ? null : ls,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontVariations: [
          FontVariation('wght', wght),
          FontVariation('opsz', size.clamp(6, 72).toDouble()),
        ],
      );

  static TextStyle sans({
    double size = 15,
    double wght = 400,
    bool italic = false,
    double height = 1.5,
    double ls = 0,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: Tokens.sans,
        fontFamilyFallback: const ['system-ui', 'sans-serif'],
        fontSize: size,
        height: height,
        letterSpacing: ls == 0 ? null : ls,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontVariations: [FontVariation('wght', wght)],
      );

  // ---- named roles (clamp() emulated against the viewport width) ----

  static double _clamp(double min, double preferred, double max) =>
      preferred.clamp(min, max).toDouble();

  static TextStyle h1(BuildContext c, Color ink) => serif(
        size: _clamp(2.4 * 16, MediaQuery.sizeOf(c).width * .08, 3.6 * 16),
        wght: 300,
        height: 1.04,
        ls: -.02 * (2.4 * 16),
        color: ink,
      );

  static TextStyle stageTime(BuildContext c, Color ink) => sans(
        size: _clamp(3.2 * 16, MediaQuery.sizeOf(c).width * .15, 5.4 * 16),
        wght: 300,
        height: 1,
        ls: -.04 * (3.2 * 16),
        color: ink,
      );

  static TextStyle stageTask(BuildContext c, Color ink) => serif(
        size: _clamp(1.8 * 16, MediaQuery.sizeOf(c).width * .06, 2.6 * 16),
        wght: 300,
        height: 1.2,
        color: ink,
      );

  static TextStyle h2(Color ink) => serif(size: 2 * 16, wght: 300, height: 1.15, ls: -.01 * 32, color: ink);
  static TextStyle taskText(Color ink) => serif(size: 1.35 * 16, wght: 400, height: 1.3, color: ink);
  static TextStyle body(Color ink) => sans(size: 15, wght: 400, height: 1.5, color: ink);
  static TextStyle meta(Color ink2) => sans(size: 13, wght: 400, color: ink2);
  static TextStyle empty(Color ink2) => serif(size: 1.35 * 16, wght: 300, italic: true, height: 1.4, color: ink2);
  static TextStyle addInput(Color ink) => serif(size: 1.25 * 16, wght: 400, italic: true, color: ink);
  static TextStyle note(Color ink2) => serif(size: 1.2 * 16, wght: 300, italic: true, height: 1.5, color: ink2);
  static TextStyle sceneChip(Color ink) => serif(size: 1.15 * 16, wght: 400, color: ink);
  static TextStyle logoTitle(Color ink) => serif(size: 1.4 * 16, wght: 300, italic: true, height: 1.1, color: ink);
  static TextStyle logoSmall(Color ink2) =>
      sans(size: 10.5, wght: 500, ls: .2 * 10.5, color: ink2).copyWith();
  static TextStyle mbig(Color ink) => serif(size: 4.2 * 16, wght: 300, height: 1, ls: -.03 * 67, color: ink);
  static TextStyle bankValue(Color ink) => serif(size: 1.9 * 16, wght: 300, color: ink);
  static TextStyle trackTitle(Color ink) => serif(size: 1.1 * 16, wght: 400, height: 1.3, color: ink);
  static TextStyle trackArtist(Color ink2) => sans(size: 12.5, wght: 400, color: ink2);
  static TextStyle nowPlaying(Color ink) => serif(size: 1.5 * 16, wght: 300, height: 1.2, color: ink);
  static TextStyle obInput(Color ink) => serif(size: 1.5 * 16, wght: 400, italic: true, color: ink);
  static TextStyle breathLabel(Color ink) => serif(size: 2.2 * 16, wght: 300, color: ink);
  static TextStyle breathCount(Color ink2) => sans(size: 1.1 * 16, wght: 400, color: ink2);
}
